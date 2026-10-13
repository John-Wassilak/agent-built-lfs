#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne renders cards in a QWebEngineView. Mnemosyne closure (operator
# request, 2026-10-12), see blfs-mnemosyne.
# Build backend: sipbuild.api. 6.10.0 is the only 6.10.x release; it builds against
# qtwebengine 6.10.2 (blfs-qtwebengine) and PyQt6 6.10.2.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 267d27275d0c79ae270bca4b03520a41fa7e85c2a4d9632da8cb9cc233a55ad1, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \
            -C --qmake="$QT6DIR/bin/qmake" $PWD
pip3 install --no-index --find-links dist --no-user PyQt6-WebEngine
