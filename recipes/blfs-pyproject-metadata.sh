#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#pyproject-metadata), which a
# book() step cannot address. Commands are the book's own (BLFS 13.0).
# The book's test block, which installs exceptiongroup from PyPI into a venv, is left
# out.
# rationale: Required by meson_python (blfs-meson-python). Mnemosyne closure (operator
# request, 2026-10-12), see blfs-mnemosyne.
# md5 f5f54a0951177667dfd7eefdfaa11372, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pyproject-metadata
