#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#pyparsing), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0).
# The book's test block, which installs matplotlib and railroad-diagrams from PyPI
# into a venv, is left out.
# rationale: Required by matplotlib. Mnemosyne closure (operator request, 2026-10-12),
# see blfs-mnemosyne.
# md5 ca3bea68cd1a84584b68cd7bed679464, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pyparsing
