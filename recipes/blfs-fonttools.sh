#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: setup.py on setuptools. FONTTOOLS_WITH_CYTHON is unset, so the
# optional Cython accelerators are not compiled and the wheel is pure Python.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 64967c6ddb0d4c610dfd8cb1485981b2d27972ddfb7d4bbbd9e199d2a089c450, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user fonttools
