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

Shares its page-parsing/classification/rendering machinery with the other per-book
extractors (bin/booklib.py) -- BLFS was the first family beyond LFS itself to need this,
onboarded before SLFS/GLFS (bin/extract-slfs.py, bin/extract-glfs.py) needed the same
thing pointed at a different book.

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
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfshost  # noqa: E402
import booklib  # noqa: E402

OVERRIDES_FILE = "blfs-overrides.json"


def header(step, page_path, ver, title):
    return [
        "#!/bin/bash",
        f"# CANDIDATE recipe extracted from the BLFS {ver}-systemd book.",
        f"# source : book/blfs-{ver}/{page_path}",
        f"# title  : {title}",
        "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
        "set -e",
        "",
    ]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    lfshost.add_host_arg(ap)
    ap.add_argument("--check", action="store_true",
                    help="validate, report drift between recipes and the book; write nothing")
    args = ap.parse_args()
    host = lfshost.resolve(args.host)

    print(f"host {host.name}: {len(lfshost.packages(host))} steps")

    plan, queue, problems, drift, new = booklib.run_family_extraction(
        lfshost.ROOT, lfshost, host, "blfs", booklib.RootAndUserinputPageParser,
        header, OVERRIDES_FILE, check=args.check)

    if problems:
        print(f"\n{len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)

    if problems and not args.check:
        sys.exit(f"\n{len(problems)} step(s) could not be planned (above). Refusing to "
                 f"write a partial plan over "
                 f"{os.path.relpath(host.blfs_plan, lfshost.ROOT)} -- fix them, or remove "
                 f"them from {os.path.relpath(host.packages, lfshost.ROOT)}, and re-run.")

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
