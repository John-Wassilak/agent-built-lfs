#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#webencodings), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by html5lib (blfs-html5lib), which qtwebengine's Chromium build
# imports. Build backend setuptools, already installed.
# md5 32f6e261d52e57bf7e1c4d41546d15b8, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user webencodings
