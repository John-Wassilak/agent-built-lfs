#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# agent-built-lfs -- extract LFS book pages into reviewable recipes
# Copyright (c) 2026 John Wassilak

"""Extract per-package command blocks from the chunked LFS book into candidate recipes.

Recipes are shared: chapters 4-11 are the same book for every machine, so recipes/ holds
one copy. Where a page's right answer is machine-specific -- which label /etc/fstab
mounts, which /boot path the kernel lands in -- the decision goes in
hosts/<host>/review-overrides.json and a second copy of that recipe is written to
hosts/<host>/recipes/, which is the one lfsbuild picks up. recipes/ keeps the neutral
candidate the next machine starts from.

  extract-recipes.py                 the host resolved from $LFS_HOST or the hostname
  extract-recipes.py --host laptop    extract for another machine from here
  extract-recipes.py --check          report drift against the book, write nothing

Output is a *candidate* only. Every recipe is reviewed against the book prose before it
runs -- the book contains optional blocks (test suites, alternative configure lines,
"if you want X" branches) that must not be concatenated blindly. Blocks inside an
admonition (note/tip/caution/warning) or inside a test-suite section are emitted
commented out and tagged, so review is a matter of reading the tags.

The unpack / cd / cleanup wrapper described in the book's General Instructions is NOT
extracted; the driver supplies it. Recipes contain only in-package commands.
"""

import argparse
import html
import json
import os
import re
import sys
from html.parser import HTMLParser

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lfshost  # noqa: E402

BOOK = f"{lfshost.ROOT}/book/13.0"
OUT = f"{lfshost.ROOT}/recipes"
OVERRIDES_FILE = "review-overrides.json"

ADMON = re.compile(r"\badmon\b")
WS = re.compile(r"\s+")


class PageParser(HTMLParser):
    """Walk a package page, capturing userinput <pre> blocks with their context."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.div_stack = []          # class attr of each open <div>
        self.blocks = []             # captured command blocks
        self.title = None
        self.in_pre = None           # 'userinput' | 'screen' | None
        self.buf = []
        self.text_buf = []           # rolling prose, for block context
        self.in_title = False
        self.sect_stack = []         # nearest section headings

    # --- tag tracking -----------------------------------------------------
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        cls = a.get("class", "")
        if tag == "div":
            self.div_stack.append(cls)
        elif tag == "pre":
            self.in_pre = "userinput" if "userinput" in cls else "screen"
            self.buf = []
        elif tag == "h1" and "sect1" in cls and self.title is None:
            self.in_title = True
            self.text_buf = []

    def handle_endtag(self, tag):
        if tag == "div":
            if self.div_stack:
                self.div_stack.pop()
        elif tag == "pre":
            if self.in_pre == "userinput":
                cmd = "".join(self.buf).strip("\n")
                if cmd.strip():
                    self.blocks.append(
                        {
                            "cmd": cmd,
                            "admon": self._admon(),
                            "divs": [d for d in self.div_stack if d],
                            "context": self._context(),
                        }
                    )
            self.in_pre = None
            self.buf = []
            self.text_buf = []
        elif tag == "h1" and self.in_title:
            self.title = WS.sub(" ", "".join(self.text_buf)).strip()
            self.in_title = False
            self.text_buf = []

    def handle_data(self, data):
        if self.in_pre == "userinput":
            self.buf.append(data)
        elif self.in_pre == "screen":
            pass
        else:
            self.text_buf.append(data)
            if len(self.text_buf) > 400:
                del self.text_buf[:-400]

    # --- helpers ----------------------------------------------------------
    def _admon(self):
        """Nearest enclosing admonition class, if any."""
        for cls in reversed(self.div_stack):
            if ADMON.search(cls):
                return cls.replace("admon", "").strip() or "admon"
        return None

    def _context(self):
        t = WS.sub(" ", "".join(self.text_buf)).strip()
        return t[-400:]


# Classification is STRUCTURAL, not prose-based.
#
# An earlier version keyed off the surrounding prose ("test suite", "known to fail").
# That was actively dangerous: in the book the test-suite paragraph sits immediately
# before "Install the package: make install", so 27 mandatory install commands --
# including gcc's and binutils' -- inherited the hint and were silently disabled.
#
# Two rules now, both structural:
#   1. the command IS a test invocation  -> disabled (tests are opt-in per package)
#   2. the block sits inside an admonition -> flagged for review (small, reviewable set)
# Everything else is a book instruction and is enabled.

TEST_CMD = re.compile(
    r"""^\s*(
          make\s+(-k\s+)?(-C\s+\S+\s+)?(check|tests?)\b
        | make\s+.*\b(check|tests?)\b
        | ninja\s+tests?\b
        | meson\s+tests?\b
        | ctest\b
        | \./?config\S*\s+test\b
        )""",
    re.X,
)

def classify(block, page):
    """Return (enabled, tags) using structural signals only."""
    tags = []
    first = (block["cmd"].splitlines() or [""])[0]

    if block["admon"]:
        tags.append(f"admon:{block['admon']}")
    if TEST_CMD.match(first):
        tags.append("testsuite")

    return (not tags), tags


def render(name, chap, base, parsed, decisions, queue):
    """Recipe text for one book page under one set of review decisions.

    Returns (text, enabled_count). `queue` collects blocks that were tagged but have no
    recorded decision yet; pass None to skip queueing (the host pass, which would
    otherwise report every block twice).
    """
    n_on = 0
    lines = [
        "#!/bin/bash",
        "# CANDIDATE recipe extracted from the LFS 13.0-systemd book.",
        f"# source : book/13.0/chapter{chap}/{base}.html",
        f"# title  : {parsed.title}",
        "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
        "# Disabled blocks are tagged with the reason; review before enabling.",
        "set -e",
        "",
    ]
    for i, b in enumerate(parsed.blocks):
        cmd = b["cmd"]
        enabled, tags = classify(b, base)
        decision = decisions.get(str(i))
        if decision:
            act = decision["action"]
            if act in ("drop", "defer"):
                enabled = False
                tags = [f"REVIEWED:{act}"]
            elif act == "enable":
                enabled = True
                tags = []
            elif act == "replace":
                enabled = True
                tags = []
                cmd = decision["cmd"]
            elif act == "test" and os.environ.get("LFSBUILD_SKIP_TESTS"):
                enabled = False
                tags = ["REVIEWED:test-skipped-this-run"]
            elif act == "test":
                # Critical test suites run, but a documented failure must not abort
                # the build. Exit status is recorded in the log for comparison.
                enabled = True
                tags = []
                cmd = (
                    "set +e\n" + cmd +
                    f"\n__rc=$?\nset -e\n"
                    f'echo "### TESTSUITE {name} block {i} exit=$__rc '
                    f'(non-fatal, compare against book)"'
                )
        n_on += enabled
        lines.append(f"# --- block {i} " + ("-" * 50))
        if b["context"]:
            for cl in re.findall(r".{1,88}(?:\s|$)", b["context"]):
                if cl.strip():
                    lines.append(f"#   ctx: {cl.strip()}")
        if tags and not decision and queue is not None:
            queue.append({"recipe": name, "block": i, "tags": tags,
                          "cmd": cmd, "context": b["context"]})
        if tags:
            if decision:
                lines.append(f"#   REVIEWED [{decision['action']}]: {decision['reason']}")
            else:
                lines.append(f"#   TAGS: {' '.join(tags)}   [DISABLED - review]")
            lines.extend("# " + l for l in cmd.splitlines())
        else:
            lines.append(cmd)
        lines.append("")

    return "\n".join(lines) + "\n", n_on


def book_pages():
    """Chapter 4-11 package pages, in filesystem order (the plan does the ordering)."""
    pages = sorted(
        p for p in (os.path.join(d, f)
                    for d, _, fs in os.walk(BOOK) for f in fs if f.endswith(".html"))
        if re.search(r"/chapter(0[4-9]|1[01])/", p)
    )
    for path in pages:
        base = os.path.basename(path)[:-5]
        chap = re.search(r"chapter(\d\d)", path).group(1)
        if base in ("chapter" + chap, "introduction"):
            continue
        yield path, chap, base


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    lfshost.add_host_arg(ap)
    ap.add_argument("--check", action="store_true",
                    help="report drift between recipes and the book; write nothing")
    args = ap.parse_args()
    host = lfshost.resolve(args.host)

    shared_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="shared")
    merged_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="merged")
    host_pages = lfshost.host_override_pages(host, OVERRIDES_FILE)

    if not args.check:
        os.makedirs(OUT, exist_ok=True)
    index, queue, drift, new = [], [], [], []

    for path, chap, base in book_pages():
        parsed = PageParser()
        parsed.feed(open(path, encoding="utf-8", errors="replace").read())
        if not parsed.blocks:
            continue
        name = f"ch{chap}-{base}"

        text, n_on = render(name, chap, base, parsed, shared_dec.get(name, {}), queue)
        shared_path = os.path.join(OUT, name + ".sh")
        if args.check:
            if not os.path.exists(shared_path):
                new.append(name)
            elif open(shared_path).read() != text:
                drift.append(name)
        else:
            with open(shared_path, "w") as f:
                f.write(text)

        if name in host_pages:
            htext, n_on = render(name, chap, base, parsed, merged_dec.get(name, {}), None)
            host_path = os.path.join(host.recipes, name + ".sh")
            rel = os.path.relpath(host_path, lfshost.ROOT)
            if args.check:
                if not os.path.exists(host_path):
                    new.append(rel)
                elif open(host_path).read() != htext:
                    drift.append(rel)
            else:
                os.makedirs(host.recipes, exist_ok=True)
                with open(host_path, "w") as f:
                    f.write(htext)

        index.append({
            "name": name, "chapter": chap, "page": base, "title": parsed.title,
            "blocks": len(parsed.blocks), "enabled": n_on,
            "disabled": len(parsed.blocks) - n_on,
            "reviewed": len(merged_dec.get(name, {})),
        })

    tot = sum(i["blocks"] for i in index)
    dis = sum(i["disabled"] for i in index)
    print(f"host {host.name}: {len(index)} recipes, {tot} blocks, {dis} disabled, "
          f"{len(queue)} awaiting review")

    if args.check:
        for label, items in (("would be CREATED", new), ("DRIFTED", drift)):
            if items:
                print(f"\n{len(items)} recipe(s) {label}:",
                      file=sys.stderr if label == "DRIFTED" else sys.stdout)
                for i in items:
                    print(f"  {i}", file=sys.stderr if label == "DRIFTED" else sys.stdout)
        print("\n--check: nothing written")
        return 1 if drift else 0

    os.makedirs(host.state, exist_ok=True)
    with open(os.path.join(host.state, "index.json"), "w") as f:
        json.dump(index, f, indent=2)
    with open(os.path.join(host.state, "review-queue.json"), "w") as f:
        json.dump(queue, f, indent=2)
    print(f"recipes -> {os.path.relpath(OUT, lfshost.ROOT)}, "
          f"index+queue -> {os.path.relpath(host.state, lfshost.ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
