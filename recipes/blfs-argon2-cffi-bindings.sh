#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by argon2-cffi. Mnemosyne closure (operator request,
# 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376).
# Pinned to 25.1.0: 26.1.0 moved to scikit-build-core, which is not installed.
# Compiles the bundled libargon2 reference source through cffi.
# Sourced from PyPI (files.pythonhosted.org), sha256
# b957f3e6ea4d55d820e40ff76f450952807013d361a65d7f28acc0acbf29229d, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user argon2-cffi-bindings
