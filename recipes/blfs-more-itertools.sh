#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by cheroot and jaraco.functools. Mnemosyne closure (operator
# request, 2026-10-12), see blfs-mnemosyne.
# Build backend: flit_core (installed).
# Sourced from PyPI (files.pythonhosted.org), sha256
# 48e8f4d9e7e5878571ecf6f2b4e57634f93cd474cc8cfbd2376f2d11b396e30d, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user more-itertools
