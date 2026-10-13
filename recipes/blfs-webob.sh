#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne's web server uses it. Mnemosyne closure (operator request,
# 2026-10-12), see blfs-mnemosyne.
# Build backend: setup.py on setuptools.
# Sourced from PyPI (files.pythonhosted.org), sha256
# aa8c27231070b135c025e567a9cd7eda03f4df71352ffaac740cb6a75f0f81a5, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user webob
