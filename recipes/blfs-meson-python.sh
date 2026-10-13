#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#meson_python), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# The book's test block, which installs the test group from PyPI into a venv, is left
# out.
# rationale: Build backend for NumPy, contourpy and matplotlib. Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# patchelf is Recommended at runtime; it is not installed and none of these three
# wheels needs an RPATH rewrite.
# md5 36c0a47464398008ea3939bbef334f31, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user meson_python
