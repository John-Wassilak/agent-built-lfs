#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# agent-built-lfs -- host resolution for a multi-machine LFS repo
# Copyright (c) 2026 John Wassilak

"""Host resolution for a repo that drives more than one LFS machine.

Every tool in bin/ used to hardcode ROOT = "/home/john/lfs" and reach straight into
state/, manifests/ and logs/. That works for exactly one machine. This module replaces
those literals with two lookups:

  ROOT        the repo, derived from this file's own location. Nothing is hardcoded, so
              a clone at /root/lfs on a live host distro works with no edits.
  resolve()   the machine being operated on -> hosts/<name>/, which owns that machine's
              plan, state, manifests, logs, kernel config and hardware-bound recipes.

Resolution order is --host, then $LFS_HOST, then the short hostname. The hostname
default is what makes the common case need no flag at all: on `server`, `lfsbuild
--status` means server. The flag is what lets one machine plan for another -- editing
the laptop's package list from the server, or building the laptop's tree in a chroot.

Three layers, resolved here, keep "shared where appropriate" honest:

  recipes     recipe(host, name) tries hosts/<h>/recipes/<name>.sh, then the shared
              generated tree for the book version this host pins
              (recipes/<family>-<ver>/<name>.sh), then recipes/<name>.sh.
              The host layer is for recipes bound to real hardware: the NVIDIA driver,
              this CPU's microcode blob, ffmpeg's NVENC flags. The version layer exists
              because a generated recipe is a function of one book release, and two
              machines can be on two releases -- `server` went to 13.1 on 2026-09-07
              while `laptop` stayed at 13.0. The last layer is hand-authored and belongs
              to no book version at all; no extractor ever writes there.
  overrides   overrides(host, "blfs") merges hosts/<h>/blfs-overrides.json on top of
              recipes/blfs-<ver>/overrides.json block by block. A page can therefore keep
              its shared mechanism decisions (menuconfig is not scriptable) while the host
              supplies the hardware-bound ones (which /boot path the kernel is copied to).
              The shared half is version-scoped for the same reason the recipes are: a
              decision names a block by index, and indices move between book releases.

Standard library only, like the rest of bin/ -- this has to run on the LFS system itself
where there is no package index. tomllib is stdlib from 3.11.
"""

import collections
import json
import os
import socket
import sys
import tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOSTS_DIR = f"{ROOT}/hosts"
SHARED_RECIPES = f"{ROOT}/recipes"
PACKAGES_DIR = f"{ROOT}/packages"

DEFAULT_CHROOT_TREE = "/mnt/lfs"
# Same path natively as inside the chroot, so recipes referencing ../<patch> behave
# identically in both modes.
DEFAULT_SOURCES = "/sources"


class Host:
    """One machine's slice of the repo. Paths only -- no I/O beyond reading host.toml."""

    def __init__(self, name):
        self.name = name
        self.dir = f"{HOSTS_DIR}/{name}"
        with open(f"{self.dir}/host.toml", "rb") as f:
            self.cfg = tomllib.load(f)

        build = self.cfg.get("build", {})
        self.arch = self.cfg.get("arch") or os.uname().machine
        # [books] pins each book family's version independently (SLFS/GLFS release on
        # their own cadence, separate from LFS/BLFS). `book` (scalar) is the pre-2026-09
        # key, read as a fallback for lfs/blfs when [books] is absent or partial; new
        # host.toml files should use [books] directly. blfs defaults from lfs -- they
        # release as one pair -- but can be pinned apart if that's ever needed.
        self.books = dict(self.cfg.get("books", {}))
        self.books.setdefault("lfs", self.cfg.get("book", "13.0"))
        self.books.setdefault("blfs", self.books["lfs"])
        self.books.setdefault("slfs", self.books["lfs"])
        self.books.setdefault("glfs", self.books["lfs"])
        self.book = self.books["lfs"]  # back-compat alias (this file's own --status only)
        # jobs = 0 (or absent) means "this machine's core count", which is right when the
        # laptop builds its own tree. A literal is for capping a machine that thermally
        # throttles or is doing something else at the same time.
        self.jobs = build.get("jobs") or os.cpu_count() or 4
        self.chroot_tree = build.get("chroot_tree", DEFAULT_CHROOT_TREE)
        self.sources = build.get("sources", DEFAULT_SOURCES)
        # Explicit override for lfsbuild's mode auto-detection (build.mode = "native" or
        # "chroot" in host.toml). Absent by default, which keeps detect_mode()'s
        # populated-tree/is_lfs_system() heuristic for hosts where it is reliable. Exists
        # for a host that has a leftover populated chroot tree even after deploying and
        # rebooting into the real thing -- the heuristic checks that tree before checking
        # whether this machine is itself LFS, so a stale-but-populated tree wins by
        # mistake. See hosts/laptop/host.toml for the concrete case this fixed.
        self.mode = build.get("mode")

        self.state = f"{self.dir}/state"
        self.plan = f"{self.state}/plan.json"
        self.blfs_plan = f"{self.state}/blfs-plan.json"
        self.slfs_plan = f"{self.state}/slfs-plan.json"
        self.glfs_plan = f"{self.state}/glfs-plan.json"
        self.done = f"{self.state}/completed"
        self.timings = f"{self.state}/timings.tsv"
        self.testreports = f"{self.state}/testreports"
        self.manifests = f"{self.dir}/manifests"
        self.logs = f"{self.dir}/logs"
        self.recipes = f"{self.dir}/recipes"
        self.overlay = f"{self.dir}/overlay"
        self.kernel_config = f"{self.dir}/kernel-config.sh"
        self.packages = f"{self.dir}/packages.py"
        self.report = f"{self.dir}/BUILD-REPORT.md"

    @property
    def hardware(self):
        """Reference facts from host.toml's [hardware] table. Not read by the tooling --
        it is what a person or a session reads before touching the kernel config."""
        return self.cfg.get("hardware", {})

    def __repr__(self):
        return f"<Host {self.name} arch={self.arch} jobs={self.jobs}>"


def known():
    """Host names that have a hosts/<name>/host.toml."""
    if not os.path.isdir(HOSTS_DIR):
        return []
    return sorted(d for d in os.listdir(HOSTS_DIR)
                  if os.path.exists(f"{HOSTS_DIR}/{d}/host.toml"))


def resolve(name=None):
    """--host, else $LFS_HOST, else the short hostname. Unknown name is fatal: guessing
    would silently write one machine's state into another's directory."""
    name = name or os.environ.get("LFS_HOST") or socket.gethostname().split(".")[0]
    if not os.path.exists(f"{HOSTS_DIR}/{name}/host.toml"):
        sys.exit(f"lfshost: no host '{name}' in {HOSTS_DIR}\n"
                 f"         known hosts: {', '.join(known()) or '(none)'}\n"
                 f"         pass --host <name>, set $LFS_HOST, or add "
                 f"hosts/{name}/host.toml (see README.md)")
    return Host(name)


def add_host_arg(ap):
    """Every tool takes the same flag, described the same way."""
    ap.add_argument("--host", default=None,
                    help="machine to operate on (default: $LFS_HOST, else hostname); "
                         f"known: {', '.join(known()) or '(none)'}")


# The per-host file each family's review decisions live in. The shared half is not
# listed: it is always <family>-<ver>/overrides.json, next to the recipes it explains.
HOST_OVERRIDES = {"lfs": "review-overrides.json", "blfs": "blfs-overrides.json",
                  "slfs": "slfs-overrides.json", "glfs": "glfs-overrides.json"}


def family_of(name):
    """Which book family a step belongs to, from its name alone.

    LFS steps are named for the book's own chapters (ch08-bash); every other family
    prefixes its own name (blfs-glib2, slfs-htop, glfs-libglvnd).
    """
    for f in ("blfs", "slfs", "glfs"):
        if name.startswith(f + "-"):
            return f
    return "lfs"


def shared_recipes(host, family):
    """The shared generated tree for the book version this host pins."""
    return f"{SHARED_RECIPES}/{family}-{host.books[family]}"


def recipe(host, name):
    """Path to the recipe for `name`: host, then this host's book version, then hand.

    A miss on all three returns the hand-authored path, so the caller's own "no recipe
    at ..." error names the file a human would have to write.
    """
    for p in (f"{host.recipes}/{name}.sh",
              f"{shared_recipes(host, family_of(name))}/{name}.sh"):
        if os.path.exists(p):
            return p
    return f"{SHARED_RECIPES}/{name}.sh"


def recipe_is_host(host, name):
    return os.path.exists(f"{host.recipes}/{name}.sh")


def _read_json(path):
    if not os.path.exists(path):
        return {}
    with open(path) as f:
        return json.load(f, object_pairs_hook=collections.OrderedDict)


def overrides(host, family, layer="merged"):
    """Review decisions for the extractors.

    layer="shared" -> recipes/<family>-<ver>/overrides.json alone, which is what that
    version's shared recipe tree is generated from. layer="merged" -> that with
    hosts/<h>/<family file> applied on top, page by page and block by block, which is
    what a host recipe is generated from.
    The per-block merge is the point: ch10-kernel keeps the shared "menuconfig is not
    scriptable" decision and takes only its /boot paths from the host.
    """
    shared = _read_json(f"{shared_recipes(host, family)}/overrides.json")
    if layer == "shared":
        return shared
    for page, blocks in _read_json(f"{host.dir}/{HOST_OVERRIDES[family]}").items():
        if page.startswith("_"):
            continue
        shared.setdefault(page, collections.OrderedDict()).update(blocks)
    return shared


def host_override_pages(host, family):
    """Pages the host has its own decisions for -- the set that needs a host recipe
    generated alongside the shared candidate."""
    return {p for p in _read_json(f"{host.dir}/{HOST_OVERRIDES[family]}")
            if not p.startswith("_")}


def packages(host):
    """Import hosts/<h>/packages.py and return its PACKAGES list.

    packages/ is put on sys.path first so the host module's `from base import BASE`
    resolves to the shared core.
    """
    import importlib.util
    for d in (PACKAGES_DIR, host.dir):
        if d not in sys.path:
            sys.path.insert(0, d)
    spec = importlib.util.spec_from_file_location(f"packages_{host.name}", host.packages)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.PACKAGES


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="show resolved host paths")
    add_host_arg(ap)
    h = resolve(ap.parse_args().host)
    print(f"root       : {ROOT}")
    books = "  ".join(f"{k}={v}" for k, v in h.books.items())
    print(f"host       : {h.name}  arch={h.arch}  jobs={h.jobs}")
    print(f"books      : {books}")
    print(f"state      : {h.state}")
    print(f"manifests  : {h.manifests}")
    print(f"logs       : {h.logs}")
    print(f"recipes    : {h.recipes} -> "
          f"{', '.join(os.path.relpath(shared_recipes(h, f), ROOT) for f in HOST_OVERRIDES)}"
          f" -> {os.path.relpath(SHARED_RECIPES, ROOT)} (hand-authored)")
    print(f"sources    : {h.sources}  chroot_tree={h.chroot_tree}")
    for k, v in h.hardware.items():
        print(f"  hw.{k:<10} {v}")
