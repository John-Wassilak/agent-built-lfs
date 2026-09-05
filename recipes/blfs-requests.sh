#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-05): khal + vdirsyncer (CLI calendar client
# and CalDAV/CardDAV sync tool). Neither package nor its dependency closure is in
# BLFS (general/python-modules.html covers a fixed set of modules on one page, not
# this closure). Pure-Python PyPI package, same pip3-wheel pattern as pyyaml/mako.
# Build backend: setuptools.build_meta (already present).
# Runtime deps (via --no-deps, installed as separate steps in this same closure): charset-normalizer, idna, urllib3, certifi.
# Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against
# PyPI's own published digest.
set -e

pip3 wheel -w dist --no-build-isolation --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user requests
