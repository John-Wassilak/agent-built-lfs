#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne hashes sync-server passwords with it and imports it at module
# level in mnemosyne/pyqt_ui/configuration_wdgt_servers.py. Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: hatchling with hatch-vcs and hatch-fancy-pypi-readme.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 694ae5cc8a42f4c4e2bf2ca0e64e51e23a040c6a517a85074683d3959e1346c1, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user argon2-cffi
