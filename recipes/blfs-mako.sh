#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: general/python-modules.html covers dozens of Python modules on one page -- doesn't fit the one-page-per-package PACKAGES model the extractor uses everywhere else, so this is the book's own generic pattern (pip3 wheel, then pip3 install from the wheel) applied by hand. Required by Mesa's build-time code generation scripts (not a runtime dep).
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user Mako

