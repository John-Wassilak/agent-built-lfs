#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Mnemosyne's GUI. Mnemosyne closure (operator request, 2026-10-12), see
# blfs-mnemosyne.
# Build backend: sipbuild.api (blfs-sip, blfs-pyqt-builder). Pinned to 6.10.2 to match
# the installed Qt 6.10.2 under /opt/qt6; it builds a module for each Qt module that
# qmake reports, so the set follows this host's trimmed qt6.
# Sourced from PyPI (files.pythonhosted.org), sha256
# 6c0db5d8cbb9a3e7e2b5b51d0ff3f283121fa27b864db6d2f35b663c9be5cc83, matching PyPI's
# published digest.
set -e

# --confirm-license accepts PyQt6's GPL v3 terms non-interactively.
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir \
            -C --confirm-license= -C --qmake="$QT6DIR/bin/qmake" $PWD
# --force-reinstall --no-deps: a rebuild of the same version (here, to pick up
# QtWebChannel once qtwebchannel was installed, 2026-10-13) is otherwise "Requirement
# already satisfied", installs nothing, and leaves a 0-file manifest.
pip3 install --no-index --find-links dist --no-user --force-reinstall --no-deps PyQt6
