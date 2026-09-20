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
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lfshost  # noqa: E402
import booklib  # noqa: E402

OUT = f"{lfshost.ROOT}/recipes"
OVERRIDES_FILE = "review-overrides.json"

PageParser = booklib.PageParser
classify = booklib.classify


def render(name, chap, base, ver, parsed, decisions, queue):
    """Recipe text for one book page under one set of review decisions.

    Returns (text, enabled_count). `queue` collects blocks that were tagged but have no
    recorded decision yet; pass None to skip queueing (the host pass, which would
    otherwise report every block twice).
    """
    header = [
        "#!/bin/bash",
        f"# CANDIDATE recipe extracted from the LFS {ver}-systemd book.",
        f"# source : book/{ver}/chapter{chap}/{base}.html",
        f"# title  : {parsed.title}",
        "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
        "# Disabled blocks are tagged with the reason; review before enabling.",
        "set -e",
        "",
    ]
    body, n_on = booklib.render_body(name, parsed, decisions, queue)
    return "\n".join(header + body) + "\n", n_on


def book_pages(book_dir):
    """Chapter 4-11 package pages, in filesystem order (the plan does the ordering)."""
    pages = sorted(
        p for p in (os.path.join(d, f)
                    for d, _, fs in os.walk(book_dir) for f in fs if f.endswith(".html"))
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
    book_dir = booklib.book_root(lfshost.ROOT, host, "lfs")
    booklib.require_book(lfshost.ROOT, book_dir, "lfs")
    ver = host.books["lfs"]

    shared_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="shared")
    merged_dec = lfshost.overrides(host, OVERRIDES_FILE, layer="merged")
    host_pages = lfshost.host_override_pages(host, OVERRIDES_FILE)

    if not args.check:
        os.makedirs(OUT, exist_ok=True)
    index, queue, drift, new = [], [], [], []

    for path, chap, base in book_pages(book_dir):
        parsed = PageParser()
        parsed.feed(open(path, encoding="utf-8", errors="replace").read())
        if not parsed.blocks:
            continue
        name = f"ch{chap}-{base}"

        text, n_on = render(name, chap, base, ver, parsed, shared_dec.get(name, {}), queue)
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
            htext, n_on = render(name, chap, base, ver, parsed, merged_dec.get(name, {}), None)
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

    if not index:
        sys.exit(f"{os.path.relpath(book_dir, lfshost.ROOT)} yielded no package pages -- "
                 f"the book looks incomplete. Refusing to write an empty index over a "
                 f"good one.")

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
