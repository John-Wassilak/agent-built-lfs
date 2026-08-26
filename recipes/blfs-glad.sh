#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/glad.html
# title  : Glad-2.0.8
# rationale: Required by libplacebo (tier 13). Python package built as a wheel
# and installed with pip3, per the book's exact commands.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir "$PWD"
pip3 install --no-index --find-links dist --no-user glad2

echo "### version"
glad --version 2>&1 || true
