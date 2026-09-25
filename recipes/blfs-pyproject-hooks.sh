#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#pyproject-hooks), which a
# book() step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: required by build (blfs-pypa-build), which nmap's Makefile runs to
# produce its ndiff and zenmap wheels. Build backend: flit_core, already installed.
# md5 ed3dd1b984339e83e35f676d7169c192, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pyproject_hooks
