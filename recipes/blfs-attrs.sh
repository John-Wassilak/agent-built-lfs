#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. libei's book page lists it as Required ('Required attrs-25.4.0') -- a pure-Python package, same pip3-wheel pattern as pyyaml/mako, except *without* --no-build-isolation: unlike pyyaml/mako (setuptools, already present), attrs' build backend is hatchling, not installed -- discovered via a real 'Cannot import hatchling.build' failure. Letting pip's normal isolated build fetch hatchling itself (this target has direct internet access on the live system) into a throwaway build venv is simpler and more honest than hand-vendoring hatchling as its own recipe; the final `pip3 install` step of *this* package still installs only the offline-built attrs wheel, no network involved. Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against PyPI's own published digest for the 25.4.0 sdist.
# DNS fix added 2026-09-09 (fresh chroot build): pip's isolated build env fetching
# hatchling from pypi.org failed with a name-resolution error -- this chroot has no
# working /etc/resolv.conf by default, same class of issue as blfs-rust/blfs-cbindgen/
# blfs-claude-code and others.
set -e

_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

pip3 wheel -w dist --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user attrs

