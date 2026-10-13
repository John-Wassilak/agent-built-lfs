#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: the sdist's in-tree backend (_custom_build/backend.py) on setuptools,
# with pybind11 (blfs-pybind11). It links whichever of zlib, libjpeg-turbo, libtiff,
# freetype, lcms2, libwebp and openjpeg2 are installed; all seven are here.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 3b8182a766685eaa002637e28b4ec8d6b18819a0c71f579bf0dbaa5830297cce, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pillow
