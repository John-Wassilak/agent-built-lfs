#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#editables), which a book()
# step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: Required by Hatchling (blfs-hatchling).
# md5 520de8c3a9dc5dfb2b365d104541c9de, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user editables
