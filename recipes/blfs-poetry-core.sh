#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne's [build-system] backend. Mnemosyne closure (operator request,
# 2026-10-12), see blfs-mnemosyne.
# Build backend: poetry.core.masonry.api from its own src/ (backend-path), no other
# build requirements; its runtime dependencies are vendored.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 20cb71be27b774628da9f384effd9183dfceb53bcef84063248a8672aa47031f, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user poetry-core
