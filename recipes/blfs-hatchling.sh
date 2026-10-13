#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#hatchling), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Build backend for legacy-cgi and argon2-cffi. Mnemosyne closure (operator
# request, 2026-10-12), see blfs-mnemosyne. Required: editables, pathspec, pluggy (seq
# 377) and trove-classifiers.
# md5 0d40370d4684147d6e3d1e3800298bd0, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user hatchling
