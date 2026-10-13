#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376). Also requires
# cppy (blfs-cppy). Compiles one C++ extension.
# Sourced from PyPI (files.pythonhosted.org), sha256
# f1303ef2eec81262a4b708c3e858afe58d7c75ad91c1c05266eda7673369859a, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user kiwisolver
