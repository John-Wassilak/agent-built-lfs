#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#pytest), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0); the book's test block
# is left out, since it installs pytest[dev] from PyPI into a venv.
# rationale: operator request. Required: iniconfig (blfs-iniconfig), pluggy
# (blfs-pluggy) and Pygments, already installed. Build backend: setuptools with
# setuptools_scm (blfs-setuptools-scm), the book's Recommended dependency.
# md5 ce26088b3b97ab8fed58c8883de23241, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pytest
