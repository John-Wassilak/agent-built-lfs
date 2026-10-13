#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne's statistics dialog plots with it
# (mnemosyne/pyqt_ui/statistics_wdgts_plotting.py, backend_qtagg). Mnemosyne closure
# (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: mesonpy with pybind11 and setuptools_scm. Its [build-system] caps
# meson-python <0.17; 0.19.0 is what is installed and the cap is not enforced without
# build isolation (3.11.x lifted it to !=0.17.*).
# Version: 3.10.9, not 3.11.2. 3.11 bundles HarfBuzz, libraqm and SheenBidi as meson
# subprojects as well; 3.10.9 needs only qhull, and builds against the system FreeType
# with -Dsystem-freetype=true.
# Sourced from PyPI (files.pythonhosted.org), sha256
# fd66508e8c6877d98e586654b608a0456db8d7e8a546eb1e2600efd957302358, matching PyPI's
# published digest.
set -e

# Bundled qhull: meson would download qhull-8.0.2.tgz at configure time. Seed the
# wrap's package cache from the sources directory instead (sha256 8774e9a1...4f8b,
# matching subprojects/qhull.wrap, fetched from github.com/qhull/qhull v8.0.2).
mkdir -p subprojects/packagecache
cp ../qhull-8.0.2.tgz subprojects/packagecache/

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \
            -C setup-args=-Dsystem-freetype=true $PWD
pip3 install --no-index --find-links dist --no-user matplotlib
