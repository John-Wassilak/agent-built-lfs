#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#cython), which a book() step cannot
# address. Commands are the book's own (BLFS 13.0).
# rationale: Required by NumPy (blfs-numpy). Mnemosyne closure (operator request,
# 2026-10-12), see blfs-mnemosyne.
# md5 a2bfdf20b8dbc2342d4105faf61d9f17, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user Cython
