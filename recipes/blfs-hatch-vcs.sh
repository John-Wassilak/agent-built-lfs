#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#hatch_vcs), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: argon2-cffi's [build-system] requires it. Required: hatchling and
# setuptools_scm (seq 376).
# md5 9a22a9f7203783e526959d34510a9672, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user hatch_vcs
