#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#iniconfig), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by pytest (blfs-pytest). The page lists hatch_vcs as Required,
# but iniconfig-2.3.0's own pyproject.toml declares setuptools>=77 and
# setuptools-scm>=8 as its build-system, with setuptools.build_meta as the backend.
# Neither hatchling nor hatch_vcs is used, so neither is built here.
# md5 5c1d9c21275feb3da71400bf716edd72, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user iniconfig
