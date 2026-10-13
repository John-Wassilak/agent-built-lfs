#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#numpy), which a book() step cannot
# address. Commands are the book's own (BLFS 13.0); the book's test block is left out,
# since it installs hypothesis from PyPI into a venv.
# rationale: Required by matplotlib and contourpy. Mnemosyne closure (operator
# request, 2026-10-12), see blfs-mnemosyne.
# No BLAS/LAPACK is installed, hence the book's own -Dallow-noblas=true.
# md5 932b0ab9e9a555c3a960d3f9ce82c425, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \
            -C setup-args=-Dallow-noblas=true $PWD
pip3 install --no-index --find-links dist --no-user numpy
