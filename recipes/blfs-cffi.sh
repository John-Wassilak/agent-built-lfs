#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by argon2-cffi-bindings (>= 2 on Python 3.14). Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta. Links the system libffi.
# Sourced from PyPI (files.pythonhosted.org), sha256
# dd31f52ea1086513bb9df30f8fcee9b8918323ae067a3d5b78bc826a000712be, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user cffi
