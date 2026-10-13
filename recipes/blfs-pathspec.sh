#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#pathspec), which a book() step
# cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by Hatchling (blfs-hatchling).
# md5 18d9e6adb72e544b56a88c3e53094b4e, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user pathspec
