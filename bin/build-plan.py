#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
#
# agent-built-lfs -- produce a host's ordered LFS build plan
# Copyright (C) 2026 John Wassilak
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://www.gnu.org/licenses/>.

"""Produce a host's ordered LFS build plan: book order, execution context, source tarball.

Reads the recipe index the extractor wrote for that host and writes hosts/<host>/state/
plan.json. Book order is identical on every machine -- what differs is only which
recipes carry host overrides, which the index already accounts for.

Ordering comes from the section number in each page's sect1 title ("8.30. GCC-15.2.0"),
which is the book's own order -- not filesystem order.

Execution context per chapter:
  ch04/05/06        -> run as the unprivileged `lfs` user on the host
  ch07 pre-chroot   -> run as root on the host (changingowner, kernfs, chroot)
  ch07 post + 08-11 -> run as root inside the chroot
"""

import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lfshost  # noqa: E402

MD5 = f"{lfshost.ROOT}/book/md5sums"

# Pages that are procedures, not package builds: no tarball, no unpack, no cleanup.
NO_PACKAGE = {
    "ch04-creatingminlayout", "ch04-addinguser", "ch04-settingenvironment",
    "ch07-changingowner", "ch07-kernfs", "ch07-chroot", "ch07-creatingdirs",
    "ch07-createfiles", "ch07-cleanup",
    "ch08-pkgmgt", "ch08-aboutdebug", "ch08-stripping", "ch08-cleanup",
    "ch09-network", "ch09-udev", "ch09-symlinks", "ch09-clock", "ch09-console",
    "ch09-locale", "ch09-inputrc", "ch09-etcshells", "ch09-systemd-custom",
    "ch10-fstab", "ch10-grub",
    "ch11-theend", "ch11-getcounted", "ch11-reboot", "ch11-whatnow", "ch11-afterlfs",
}

# Pages whose tarball name is not derivable from the page name.
# Verified against the 92 entries in book/md5sums.
TARBALL_OVERRIDE = {
    "gcc-pass1": "gcc",
    "gcc-pass2": "gcc",
    "gcc-libstdc++": "gcc",
    "binutils-pass1": "binutils",
    "binutils-pass2": "binutils",
    "linux-headers": "linux",
    "kernel": "linux",
    "xml-parser": "XML-Parser",
    "Python": "Python",
    "tcl": "tcl",
    "sqlite": "sqlite-autoconf",
    "libstdc++": "gcc",
}

# Tarballs whose filename defies stem matching entirely (verified against md5sums).
EXACT_TARBALL = {
    "flit-core": "flit_core-3.12.0.tar.gz",   # underscore, not hyphen
    "libelf": "elfutils-0.194.tar.bz2",       # libelf ships inside elfutils
    "tcl": "tcl8.6.17-src.tar.gz",            # no separator before the version
    "expect": "expect5.45.4.tar.gz",          # no separator before the version
}

# Pre-chroot ch07 procedures run as root on the host, not inside the chroot.
CH07_HOST = {"ch07-changingowner", "ch07-kernfs", "ch07-chroot"}

# Chapter 4 is split: 4.2 (dir layout) and 4.3 (adding the lfs user) are root
# operations on the host; only 4.4 (the lfs shell environment) runs as lfs.
CH04_ROOT = {"ch04-creatingminlayout", "ch04-addinguser"}


def load_tarballs(MD5=MD5):
    names = []
    for line in open(MD5):
        parts = line.split()
        if len(parts) == 2:
            names.append(parts[1])
    return names


def match_tarball(page, title, tarballs):
    if page in EXACT_TARBALL:
        return EXACT_TARBALL[page]
    stem = TARBALL_OVERRIDE.get(page, page)
    # Version from the title, e.g. "8.30. GCC-15.2.0" -> 15.2.0
    m = re.match(r"\s*[\d.]+\.\s*(.+?)\s*(?:-\s*Pass\s*\d)?\s*$", title or "")
    label = m.group(1) if m else stem

    # Patches share the package prefix; they are applied *by* the recipe, never
    # unpacked as the source. Excluding them here is what keeps e.g. coreutils
    # from matching coreutils-9.10-i18n-1.patch instead of coreutils-9.10.tar.xz.
    cands = [
        t for t in tarballs
        if t.lower().startswith(stem.lower() + "-") and not t.endswith(".patch")
    ]
    if len(cands) == 1:
        return cands[0]
    if len(cands) > 1:
        # Disambiguate with the version from the title.
        vm = re.search(r"-([\d][\w.]*)$", label)
        if vm:
            v = vm.group(1)
            exact = [t for t in cands if v in t]
            if len(exact) == 1:
                return exact[0]
        return sorted(cands)[0]
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    lfshost.add_host_arg(ap)
    args = ap.parse_args()
    host = lfshost.resolve(args.host)

    index_path = os.path.join(host.state, "index.json")
    if not os.path.exists(index_path):
        sys.exit(f"build-plan: no recipe index at {os.path.relpath(index_path, lfshost.ROOT)}"
                 f" -- run extract-recipes.py --host {host.name} first")
    idx = json.load(open(index_path))
    tarballs = load_tarballs()

    rows = []
    unmatched = []
    for e in idx:
        name, page, chap, title = e["name"], e["page"], e["chapter"], e["title"] or ""
        m = re.match(r"\s*(\d+)\.(\d+)\.", title)
        order = (int(m.group(1)), int(m.group(2))) if m else (int(chap), 999)

        if name in CH04_ROOT:
            ctx = "root-host"
        elif chap in ("04", "05", "06"):
            ctx = "lfs"
        elif name in CH07_HOST:
            ctx = "root-host"
        else:
            ctx = "chroot"

        if name in NO_PACKAGE:
            tb = ""
        else:
            tb = match_tarball(page, title, tarballs) or ""
            if not tb:
                unmatched.append((name, title))

        rows.append(
            {
                "order": order,
                "name": name,
                "chapter": chap,
                "page": page,
                "title": title,
                "context": ctx,
                "tarball": tb,
                "enabled": e["enabled"],
                "disabled": e["disabled"],
            }
        )

    rows.sort(key=lambda r: r["order"])
    for i, r in enumerate(rows, 1):
        r["seq"] = i
        r["order"] = f"{r['order'][0]}.{r['order'][1]}"

    os.makedirs(host.state, exist_ok=True)
    with open(host.plan, "w") as f:
        json.dump(rows, f, indent=2)

    print(f"{len(rows)} steps -> {os.path.relpath(host.plan, lfshost.ROOT)}")
    ctxc = {}
    for r in rows:
        ctxc[r["context"]] = ctxc.get(r["context"], 0) + 1
    print("contexts:", ", ".join(f"{k}={v}" for k, v in sorted(ctxc.items())))
    pk = sum(1 for r in rows if r["tarball"])
    print(f"package builds: {pk}   procedures: {len(rows) - pk}")
    if unmatched:
        print(f"\nUNMATCHED tarball ({len(unmatched)}) -- need override:")
        for n, t in unmatched:
            print(f"  {n:28} {t}")
    else:
        print("\nall package steps matched a tarball")


if __name__ == "__main__":
    main()
