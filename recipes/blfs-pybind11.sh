#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Build-time dependency of contourpy, pillow and matplotlib. Mnemosyne
# closure (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: setuptools.build_meta. Pinned to 2.13.6, the last release on
# setuptools: pybind11 3.x builds with scikit-build-core, which is not installed.
# matplotlib and contourpy both accept >=2.13.2,!=2.13.3.
# Installs the pybind11-config script that meson's pybind11 dependency lookup uses.
# Sourced from PyPI (files.pythonhosted.org), sha256
# ba6af10348c12b24e92fa086b39cfba0eff619b61ac77c406167d813b096d39a, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pybind11
