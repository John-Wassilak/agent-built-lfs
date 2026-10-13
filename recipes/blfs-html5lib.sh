#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#html5lib), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0).
# The book's Required patch, html5lib-1.1-python_3.14_buildfix-1.patch, is fetched
# from linuxfromscratch.org/patches/blfs/13.0/ into the sources directory.
# rationale: Required by qtwebengine (x/qtwebengine.html). Its other Required
# dependency, six, is already installed (seq 259).
# md5 6748742e2ec4cb99287a6bc82bcfe2b0, matching the book.
set -e

patch -Np1 -i ../html5lib-1.1-python_3.14_buildfix-1.patch

sed -i 's/from pkg_resources import/from packaging.version import parse as/' setup.py &&
sed -i 's/import pkg_resources/pkg_resources = None/' setup.py

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user html5lib
