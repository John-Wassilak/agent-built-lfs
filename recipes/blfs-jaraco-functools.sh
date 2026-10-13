#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by cheroot. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376).
# Pinned to 4.1.0: 4.2.0 and later add coherent.licensed to [build-system], which
# nothing else here needs.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 70f7e0e2ae076498e212562325e805204fc092d7b4c17e0e86c959e249701a9d, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user jaraco.functools
