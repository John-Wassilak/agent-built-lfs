#!/usr/bin/env python3
"""Extract BLFS recipes for the minimal set needed to run Claude Code in the LFS system.

Reuses the LFS extractor's page parser and classifier, so BLFS packages get the same
treatment: candidate recipes from the book, review decisions persisted in
recipes/blfs-overrides.json, and per-package manifests from the driver.

Scope is deliberately tight -- the dependency closure of the four things asked for:

  DHCP     already provided by systemd-networkd from LFS; nothing to build.
  which    the ONLY hard requirement of Node.js.
  libtasn1 -> p11-kit -> make-ca   the CA certificate store. Without it npm and
           Claude Code cannot complete a single TLS handshake; /etc/ssl/certs is
           empty on a by-the-book LFS system.
  nodejs   provides npm. Built with its bundled brotli/c-ares/ICU/libuv/nghttp2,
           which BLFS lists only as "recommended" -- taking the bundled copies keeps
           the closure small and uses the versions upstream tests against.
  openssh  ssh and sshd. No required dependencies beyond LFS.
  curl/wget  not needed by Claude Code, but dependencies of a large share of BLFS,
           so worth having now. Closure: libunistring -> libidn2 -> libpsl.

Order below is dependency order and is what the plan preserves.
"""

import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BOOK = f"{ROOT}/book/blfs-13.0"
OUT = f"{ROOT}/recipes"
STATE = f"{ROOT}/state"
OVERRIDES = f"{OUT}/blfs-overrides.json"

# Reuse the LFS extractor rather than duplicating the parser.
_spec = importlib.util.spec_from_file_location("lfsx", f"{HERE}/extract-recipes.py")
lfsx = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lfsx)

class BlfsPageParser(lfsx.PageParser):
    """BLFS marks root-only commands with <pre class="root">, and that is where every
    `make install` lives. The LFS parser only captures class="userinput", which silently
    dropped the install step from every BLFS recipe. Capture both, in document order,
    and record which class each came from -- inside the chroot we are root either way."""

    def handle_starttag(self, tag, attrs):
        if tag == "pre":
            cls = dict(attrs).get("class", "")
            if "userinput" in cls or "root" in cls:
                self.in_pre = "userinput"
                self._src_class = cls
            else:
                self.in_pre = "screen"
            self.buf = []
            return
        super().handle_starttag(tag, attrs)


# (name, book page, source tarball, capture manifest)
PACKAGES = [
    ("which",    "general/which.html",     "which-2.23.tar.gz"),
    ("libtasn1", "general/libtasn1.html",  "libtasn1-4.21.0.tar.gz"),
    ("p11-kit",  "postlfs/p11-kit.html",   "p11-kit-0.26.2.tar.xz"),
    ("make-ca",  "postlfs/make-ca.html",   "make-ca-1.16.1.tar.gz"),
    ("openssh",  "postlfs/openssh.html",   "openssh-10.2p1.tar.gz"),
    ("nodejs",   "general/nodejs.html",    "node-v22.22.0.tar.xz"),
    # Added after the fact: curl and wget are required or recommended by a large
    # share of BLFS, so having them present saves repeated detours later. Their
    # closure is libunistring -> libidn2 -> libpsl. libpsl is not optional in
    # practice: BLFS notes that building curl without it has "severe security
    # implications" (it is what stops cookies being set across public suffixes).
    ("libunistring", "general/libunistring.html", "libunistring-1.4.1.tar.xz"),
    ("libidn2",      "general/libidn2.html",      "libidn2-2.3.8.tar.gz"),
    ("libpsl",       "basicnet/libpsl.html",      "libpsl-0.21.5.tar.gz"),
    ("curl",         "basicnet/curl.html",        "curl-8.18.0.tar.xz"),
    ("wget",         "basicnet/wget.html",        "wget-1.25.0.tar.gz"),
]



# Steps with no BLFS book page. These recipes are HAND-AUTHORED, not extracted, and
# say so in their header so nobody mistakes them for book text.
EXTRA_STEPS = [
    {
        "name": "sshd-unit",
        "tarball": "blfs-systemd-units-20251204.tar.xz",
        "why": "The openssh page points at blfs-systemd-units for sshd.service; "
               "'make install-sshd' is that package's target, not openssh's.",
        "cmd": """# DESTDIR=/ installs to the right place AND makes the Makefile skip its
# `systemctl enable`, which cannot run in the chroot. Same trick, no patching.
make install-sshd DESTDIR=/

# Enable sshd.service by hand -- exactly what `systemctl enable` would do.
install -vdm755 /etc/systemd/system/multi-user.target.wants
ln -sfv /usr/lib/systemd/system/sshd.service \\
        /etc/systemd/system/multi-user.target.wants/sshd.service

# BLFS's sshd.service has no host-key generation, and sshd refuses to start without
# host keys. Generate them on first start instead of baking them into the image, so
# the tree stays safe to copy: ssh-keygen -A only creates what is missing.
install -vdm755 /etc/systemd/system/sshd.service.d
cat > /etc/systemd/system/sshd.service.d/keygen.conf << "EOF"
[Service]
ExecStartPre=/usr/bin/ssh-keygen -A
EOF

sshd -t -f /etc/ssh/sshd_config 2>&1 | grep -v "no hostkeys available" || true
echo "### sshd.service enabled; host keys generated on first start"
""",
    },
    {
        "name": "claude-code",
        "tarball": "",
        "why": "Installs Claude Code from npm. Needs working DNS inside the chroot, "
               "which the LFS resolv.conf symlink cannot provide here.",
        "cmd": """# The chroot inherits host networking, but /etc/resolv.conf is a symlink to
# systemd-resolved's stub, which does not exist without a running resolved. Supply
# DNS for the duration of the install and restore the symlink no matter what.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\\nnameserver 8.8.8.8\\n' > /etc/resolv.conf

npm install -g @anthropic-ai/claude-code

echo "### versions"
node --version
npm --version
claude --version
""",
    },
]


def load_overrides():
    try:
        raw = json.load(open(OVERRIDES))
    except FileNotFoundError:
        return {}
    return {k: v for k, v in raw.items() if not k.startswith("_")}


def main():
    os.makedirs(OUT, exist_ok=True)
    overrides = load_overrides()
    plan = []
    queue = []

    for seq, (name, page, tarball) in enumerate(PACKAGES, 1):
        path = os.path.join(BOOK, page)
        src = open(path, encoding="utf-8", errors="replace").read()
        p = BlfsPageParser()
        p.feed(src)

        step = f"blfs-{name}"
        ov = overrides.get(step, {})
        n_on = 0
        lines = [
            "#!/bin/bash",
            f"# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.",
            f"# source : book/blfs-13.0/{page}",
            f"# title  : {p.title}",
            "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
            "set -e",
            "",
        ]

        for i, b in enumerate(p.blocks):
            enabled, tags = lfsx.classify(b, name)
            decision = ov.get(str(i))
            if decision:
                act = decision["action"]
                if act in ("drop", "defer"):
                    enabled, tags = False, [f"REVIEWED:{act}"]
                elif act == "enable":
                    enabled, tags = True, []
                elif act == "replace":
                    enabled, tags = True, []
                    b["cmd"] = decision["cmd"]
            if tags and not decision:
                queue.append({"recipe": step, "block": i, "tags": tags,
                              "cmd": b["cmd"], "context": b["context"]})
            n_on += enabled

            lines.append(f"# --- block {i} " + ("-" * 50))
            if b["context"]:
                for cl in re.findall(r".{1,88}(?:\s|$)", b["context"]):
                    if cl.strip():
                        lines.append(f"#   ctx: {cl.strip()}")
            if not enabled:
                if decision:
                    lines.append(f"#   REVIEWED [{decision['action']}]: {decision['reason']}")
                else:
                    lines.append(f"#   TAGS: {' '.join(tags)}   [DISABLED - review]")
                lines.extend("# " + l for l in b["cmd"].splitlines())
            else:
                lines.append(b["cmd"])
            lines.append("")

        with open(f"{OUT}/{step}.sh", "w") as f:
            f.write("\n".join(lines) + "\n")

        plan.append({
            "seq": seq, "order": f"blfs.{seq}", "name": step,
            "chapter": "blfs", "page": name, "title": p.title,
            "context": "chroot", "tarball": tarball,
            "manifest": True,
            "blocks": len(p.blocks), "enabled": n_on,
            "disabled": len(p.blocks) - n_on,
        })
        print(f"  {step:18} {len(p.blocks):2} blocks, {n_on:2} enabled, "
              f"{len(p.blocks)-n_on:2} disabled   {p.title}")

    for k, e in enumerate(EXTRA_STEPS, len(PACKAGES) + 1):
        step = f"blfs-{e['name']}"
        body = [
            "#!/bin/bash",
            "# HAND-AUTHORED recipe -- no BLFS book page covers this step.",
            f"# rationale: {e['why']}",
            "set -e",
            "",
            e["cmd"],
        ]
        with open(f"{OUT}/{step}.sh", "w") as f:
            f.write("\n".join(body) + "\n")
        plan.append({
            "seq": k, "order": f"blfs.{k}", "name": step,
            "chapter": "blfs", "page": e["name"], "title": f"{e['name']} (hand-authored)",
            "context": "chroot", "tarball": e["tarball"], "manifest": True,
            "blocks": 1, "enabled": 1, "disabled": 0,
        })
        print(f"  {step:18} hand-authored")

    os.makedirs(STATE, exist_ok=True)
    with open(f"{STATE}/blfs-plan.json", "w") as f:
        json.dump(plan, f, indent=2)
    with open(f"{OUT}/blfs-review-queue.json", "w") as f:
        json.dump(queue, f, indent=2)

    print(f"\n{len(plan)} BLFS steps -> state/blfs-plan.json")
    print(f"{len(queue)} blocks awaiting review -> recipes/blfs-review-queue.json")


if __name__ == "__main__":
    main()
