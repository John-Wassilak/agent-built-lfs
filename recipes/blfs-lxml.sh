#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-modules.html (#lxml), which a book() step cannot
# address. Commands are the book's own (BLFS 13.0).
# rationale: itstool's Required dependency (GIMP's closure, seq 341-361). Needs
# libxslt (seq 295, already built). Build backend: setuptools, already installed.
# md5 ac9a945976227fd854d3e9e034e52ca1, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user lxml
