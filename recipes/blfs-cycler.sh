#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: setuptools.build_meta.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 88bb128f02ba341da8ef447245a9e138fae777f6a23943da4540077d3601eb1c, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user cycler
