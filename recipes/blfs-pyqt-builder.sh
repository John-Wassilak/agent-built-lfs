#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Build backend helper that PyQt6 and PyQt6-WebEngine require. Mnemosyne
# closure (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376).
# Sourced from PyPI (files.pythonhosted.org), sha256
# 267ac1ee1593c67884f3c9cb6566f72a92ca28353050fc9d087433c28c74a889, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user PyQt-builder
