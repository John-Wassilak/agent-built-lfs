#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#trove-classifiers), which a
# book() step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by Hatchling (blfs-hatchling).
# md5 ded610aa62cf3dc78360e96802ca72e8, matching the book.
set -e

sed -i '/calver/s/^/#/;$iversion="2026.1.14.14"' setup.py

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user trove-classifiers
