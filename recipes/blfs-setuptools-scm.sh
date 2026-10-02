#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#setuptools_scm), which a
# book() step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: build backend for pluggy, iniconfig and pytest (blfs-pytest). Needs
# setuptools and packaging, both already installed. Its own build backend is the
# in-tree _own_version_helper on top of setuptools, so nothing else is fetched.
# md5 72975fc3ec40a1ae06bb2d86ca8ac48d, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user setuptools_scm
