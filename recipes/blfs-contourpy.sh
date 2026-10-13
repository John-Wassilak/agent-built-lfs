#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# Build backend: mesonpy (blfs-meson-python 0.19.0, needs >= 0.18) with pybind11
# (blfs-pybind11).
# Sourced from PyPI (files.pythonhosted.org), sha256
# 20156f5a1ac4f8ce02656e39a61e82164a3d359796dc8026f75b062783d500e1, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user contourpy
