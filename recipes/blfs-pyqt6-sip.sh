#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Runtime sip module for PyQt6. Mnemosyne closure (operator request,
# 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 2cd55f575cde208c398d6cfdecc5a13394ed2afb54226210c50e3a6df7c3a997, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user PyQt6-sip
