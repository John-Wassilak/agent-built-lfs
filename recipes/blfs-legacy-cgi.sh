#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this module.
# rationale: Provides the cgi module that Python 3.13 removed;
# mnemosyne/web_server/web_server.py imports cgi and WebOb requires it on >= 3.13.
# Mnemosyne closure (operator request, 2026-10-12), see blfs-mnemosyne.
# Build backend: hatchling (blfs-hatchling).
# Sourced from PyPI (files.pythonhosted.org), sha256
# abb9dfc7835772f7c9317977c63253fd22a7484b5c9bbcdca60a29dcce97c577, matching PyPI's
# published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user legacy-cgi
