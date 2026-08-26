#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. libei's book page lists it as Required ('Required attrs-25.4.0') -- a pure-Python package, same pip3-wheel pattern as pyyaml/mako, except *without* --no-build-isolation: unlike pyyaml/mako (setuptools, already present), attrs' build backend is hatchling, not installed -- discovered via a real 'Cannot import hatchling.build' failure. Letting pip's normal isolated build fetch hatchling itself (this target has direct internet access, confirmed by every curl fetch this session) into a throwaway build venv is simpler and more honest than hand-vendoring hatchling as its own recipe; the final `pip3 install` step of *this* package still installs only the offline-built attrs wheel, no network involved. Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against PyPI's own published digest for the 25.4.0 sdist.
set -e

pip3 wheel -w dist --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user attrs

