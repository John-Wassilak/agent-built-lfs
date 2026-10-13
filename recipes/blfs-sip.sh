#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Binding generator for PyQt6 and PyQt6-WebEngine. Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376).
# Sourced from PyPI (files.pythonhosted.org), sha256
# 34e2c1389e25394f5ba3c6b9d999d04373baf8d7161410536d444f48226d2f50, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user sip
