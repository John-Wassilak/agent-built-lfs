#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by cffi. Mnemosyne closure (operator request, 2026-10-12), see
# blfs-mnemosyne.
# Build backend: setuptools.build_meta.
# Sourced from PyPI (files.pythonhosted.org), sha256
# d875f09c3507d00e1aba0eecc6dcadc1352f30fff09dc6bff2f1c2935e97c2bc, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pycparser
