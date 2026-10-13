#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne's sync and web servers use its WSGI server. Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376).
# Sourced from PyPI (files.pythonhosted.org), sha256
# bfb70c49663f63b0440f2b54dbc6b0d1650e56dfe4e2641f59b2c6f727b44aca, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user cheroot
