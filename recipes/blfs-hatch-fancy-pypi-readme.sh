#!/bin/bash
# HAND-AUTHORED recipe -- the book covers this module, but as one section of the
# multi-package page general/python-dependencies.html (#hatch-fancy-pypi-readme),
# which a book() step cannot address. Commands are the book's own (BLFS 13.0).
# rationale: argon2-cffi's [build-system] requires it. Required: hatchling.
# md5 8e1ed2416887685adc1c909ed4fb63cb, matching the book.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user hatch-fancy-pypi-readme
