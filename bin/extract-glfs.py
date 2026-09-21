#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# agent-built-lfs -- generate a host's GLFS recipes and build plan
# Copyright (c) 2026 John Wassilak

"""Generate a host's GLFS recipes and build plan from its package list.

GLFS (Gaming Linux From Scratch) supplements BLFS with graphics drivers (libglvnd,
Mesa, NVIDIA), the Xorg library/font/input-device closet BLFS itself does not carry
individually, and the rest of a gaming stack (Steam, Wine -- not used by this repo) --
with its own version cadence, independent of LFS/BLFS (host.toml's [books].glfs). A
package's packages.py entry is built with glfs(...) (packages/base.py) rather than
book(...) to say it comes from this book instead.

Unlike LFS/BLFS, GLFS ships no downloadable pre-built chunked-HTML tarball -- there is no
book/glfs-<ver>/ mirror to fetch wholesale. Its pages are read from linuxfromscratch.org's
own view/<ver>/ path and saved locally one page at a time, only for the pages a host's
packages.py actually references (same as any other book() page: this script only ever
reads book/glfs-<ver>/<html> for entries that name that path). See README.md.

GLFS's own page markup differs from LFS/BLFS's in one way: admonitions are a bare class
(e.g. class="note") rather than "admon note". bin/booklib.py's classifier already
handles both conventions, checked directly against real pages of each book.

  extract-glfs.py                  the host resolved from $LFS_HOST or the hostname
  extract-glfs.py --host laptop    plan for another machine from here
  extract-glfs.py --check          validate and report drift, write nothing
"""

import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lfshost  # noqa: E402
import booklib  # noqa: E402

def header(step, page_path, ver, title):
    return [
        "#!/bin/bash",
        f"# CANDIDATE recipe extracted from the GLFS {ver} book.",
        f"# source : book/glfs-{ver}/{page_path}",
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

    plan, queue, problems, drift, new = booklib.run_family_extraction(
        lfshost.ROOT, lfshost, host, "glfs", booklib.RootAndUserinputPageParser,
        header, check=args.check)

    if problems:
        print(f"\n{len(problems)} problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)

    if problems and not args.check:
        sys.exit(f"\n{len(problems)} step(s) could not be planned (above). Refusing to "
                 f"write a partial plan over "
                 f"{os.path.relpath(host.glfs_plan, lfshost.ROOT)} -- fix them, or remove "
                 f"them from {os.path.relpath(host.packages, lfshost.ROOT)}, and re-run.")

    if args.check:
        print(f"--check: {len(plan)} steps would be planned, nothing written")
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
    with open(host.glfs_plan, "w") as f:
        json.dump(plan, f, indent=2)
    with open(f"{host.state}/glfs-review-queue.json", "w") as f:
        json.dump(queue, f, indent=2)
    print(f"{len(plan)} steps -> {os.path.relpath(host.glfs_plan, lfshost.ROOT)}")
    print(f"{len(queue)} blocks awaiting review -> "
          f"{os.path.relpath(host.state, lfshost.ROOT)}/glfs-review-queue.json")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
