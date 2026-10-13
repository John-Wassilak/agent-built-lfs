#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Build-time C++ header helper that kiwisolver's [build-system] requires.
# Build backend: setuptools.build_meta, with setuptools_scm (seq 376). [build-system]
# also lists wheel, which setuptools >= 70.1 no longer needs.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 55b5307c11874f242ea135396f398cb67a5bbde4fab3e3c3294ea5fce43a6d68, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user cppy
