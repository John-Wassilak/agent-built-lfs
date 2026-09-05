#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-05): khal + vdirsyncer (CLI calendar client
# and CalDAV/CardDAV sync tool). Neither package nor its dependency closure is in
# BLFS (general/python-modules.html covers a fixed set of modules on one page, not
# this closure). Pure-Python PyPI package, same pip3-wheel pattern as pyyaml/mako.
# Build backend: setuptools.build_meta but needs setuptools-scm>=8.1.0 (not installed).
# Runtime deps (via --no-deps, installed as separate steps in this same closure): wcwidth, typing-extensions.
# Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against
# PyPI's own published digest.
set -e

pip3 wheel -w dist --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user urwid
