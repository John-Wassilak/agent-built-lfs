#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#pluggy), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by pytest (blfs-pytest). Build backend: setuptools with
# setuptools_scm (blfs-setuptools-scm), the book's Recommended dependency.
# md5 54391218af778acb006c2d915085d469, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pluggy
