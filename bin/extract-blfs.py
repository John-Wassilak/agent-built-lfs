#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# agent-built-lfs -- generate a host's BLFS recipes and build plan
# Copyright (c) 2026 John Wassilak

"""Generate a host's BLFS recipes and build plan from its package list.

The ordered list of steps lives in hosts/<host>/packages.py (which imports the shared
core from packages/base.py) -- not in this file. This is the machinery that turns that
list into recipes and a plan:

  book(...) steps   parsed out of the BLFS page, with review decisions applied from
                    recipes/blfs-overrides.json. Written to recipes/<step>.sh. When the
                    host has its own decisions for that page, a second copy is written to
                    hosts/<host>/recipes/<step>.sh with shared+host decisions merged --
                    that is the copy lfsbuild will pick up, and the shared one stays the
                    machine-neutral candidate the next host starts from.

  hand(...) steps   no BLFS page covers them (a proprietary driver, a Go program, a font
                    tarball). Their recipe is a hand-authored file already in the tree;
                    this script only checks it exists and puts it in the plan. It never
                    writes a hand-authored recipe, so editing one is safe.

Reuses the LFS extractor's page parser and classifier, so BLFS packages get the same
treatment as book chapters.

  extract-blfs.py                  the host resolved from $LFS_HOST or the hostname
  extract-blfs.py --host laptop    plan for another machine from here
  extract-blfs.py --check          validate and report drift, write nothing

--check is the one to run before a real extraction. It reports DRIFT for any book step
whose recipe on disk is not what the book plus the recorded review decisions produce --
which means someone edited the recipe by hand and the edit is not captured anywhere. A
regeneration would silently throw that edit away, so the fix is either to record the
edit as a review decision in blfs-overrides.json, or to make the step a hand() entry
whose recipe this script does not own.
"""

import argparse
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfshost  # noqa: E402

BOOK = f"{lfshost.ROOT}/book/blfs-13.0"
OUT = f"{lfshost.ROOT}/recipes"
OVERRIDES_FILE = "blfs-overrides.json"

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


def render(step, page_path, parsed, decisions, queue):
    """Recipe text for one book page under one set of review decisions."""
    n_on = 0
    lines = [
        "#!/bin/bash",
        "# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.",
        f"# source : book/blfs-13.0/{page_path}",
        f"# title  : {parsed.title}",
        "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
        "set -e",
        "",
    ]

    for i, b in enumerate(parsed.blocks):
        cmd = b["cmd"]
        enabled, tags = lfsx.classify(b, step)
        decision = decisions.get(str(i))
        if decision:
            act = decision["action"]
            if act in ("drop", "defer"):
                enabled, tags = False, [f"REVIEWED:{act}"]
            elif act == "enable":
                enabled, tags = True, []
            elif act == "replace":
                enabled, tags = True, []
                cmd = decision["cmd"]
        if tags and not decision and queue is not None:
            queue.append({"recipe": step, "block": i, "tags": tags,
                          "cmd": cmd, "context": b["context"]})
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
            lines.extend("# " + l for l in cmd.splitlines())
        else:
            lines.append(cmd)
        lines.append("")

    return "\n".join(lines) + "\n", n_on


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    lfshost.add_host_arg(ap)
    ap.add_argument("--check", action="store_true",
                    help="validate, report drift between recipes and the book; write nothing")
    args = ap.parse_args()
    host = lfshost.resolve(args.host)

    packages = lfshost.packages(host)
    shared_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="shared")
    merged_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="merged")
    host_pages = lfshost.host_override_pages(host, OVERRIDES_FILE)

    plan, queue, problems, drift, new = [], [], [], [], []
    print(f"host {host.name}: {len(packages)} steps")

    for p in packages:
        step = f"blfs-{p['name']}"

        if p["html"]:
            path = os.path.join(BOOK, p["html"])
            if not os.path.exists(path):
                problems.append(f"{step}: no book page at book/blfs-13.0/{p['html']}")
                continue
            parsed = BlfsPageParser()
            parsed.feed(open(path, encoding="utf-8", errors="replace").read())

            text, n_on = render(step, p["html"], parsed,
                                shared_dec.get(step, {}), queue)
            shared_path = f"{OUT}/{step}.sh"
            if args.check:
                if not os.path.exists(shared_path):
                    new.append(step)
                elif open(shared_path).read() != text:
                    drift.append(step)
            else:
                with open(shared_path, "w") as f:
                    f.write(text)

            if step in host_pages:
                htext, n_on = render(step, p["html"], parsed,
                                     merged_dec.get(step, {}), None)
                host_path = f"{host.recipes}/{step}.sh"
                if args.check:
                    rel = host_path.replace(lfshost.ROOT + "/", "")
                    if not os.path.exists(host_path):
                        new.append(rel)
                    elif open(host_path).read() != htext:
                        drift.append(rel)
                else:
                    os.makedirs(host.recipes, exist_ok=True)
                    with open(host_path, "w") as f:
                        f.write(htext)

            title = parsed.title
            blocks, enabled, disabled = len(parsed.blocks), n_on, len(parsed.blocks) - n_on
            kind = "host" if step in host_pages else "book"
        else:
            recipe = lfshost.recipe(host, step)
            if not os.path.exists(recipe):
                problems.append(f"{step}: hand-authored, but no recipe at "
                                f"{os.path.relpath(recipe, lfshost.ROOT)}")
                continue
            title = p["title"]
            blocks, enabled, disabled = p["blocks"] or 1, 1, 0
            kind = "hand*" if lfshost.recipe_is_host(host, step) else "hand"

        plan.append({
            "seq": p["seq"], "order": f"blfs.{p['seq']}", "name": step,
            "chapter": "blfs", "page": p["page"], "title": title,
            "context": "chroot", "tarball": p["tarball"], "manifest": True,
            "blocks": blocks, "enabled": enabled, "disabled": disabled,
        })
        print(f"  {step:26} {kind:5} {blocks:2} blocks, {enabled:2} enabled, "
              f"{disabled:2} disabled   {title}")

    if problems:
        print(f"\n{len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)

    if args.check:
        print(f"\n--check: {len(plan)} steps would be planned, nothing written")
        if new:
            print(f"\n{len(new)} recipe(s) would be CREATED:")
            for n in new:
                print(f"  {n}")
        if drift:
            print(f"\n{len(drift)} book step(s) DRIFTED -- regenerating would discard a "
                  f"hand edit:", file=sys.stderr)
            for d in drift:
                print(f"  {d}", file=sys.stderr)
        return 1 if (problems or drift) else 0

    os.makedirs(host.state, exist_ok=True)
    with open(host.blfs_plan, "w") as f:
        json.dump(plan, f, indent=2)
    with open(f"{host.state}/blfs-review-queue.json", "w") as f:
        json.dump(queue, f, indent=2)
    print(f"\n{len(plan)} steps -> {os.path.relpath(host.blfs_plan, lfshost.ROOT)}")
    print(f"{len(queue)} blocks awaiting review -> "
          f"{os.path.relpath(host.state, lfshost.ROOT)}/blfs-review-queue.json")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
