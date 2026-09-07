#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-05): khal + vdirsyncer (CLI calendar client
# and CalDAV/CardDAV sync tool). Neither package nor its dependency closure is in
# BLFS (general/python-modules.html covers a fixed set of modules on one page, not
# this closure). Pure-Python PyPI package, same pip3-wheel pattern as pyyaml/mako.
# Build backend: setuptools.build_meta, but pyproject.toml's [build-system] also
# requires setuptools_scm<8.0, which is NOT installed on this system.
# Runtime deps (via --no-deps, installed as separate steps in this same closure): six.
# Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against
# PyPI's own published digest.
#
# Real failure fixed 2026-09-07 (laptop): this recipe originally passed
# --no-build-isolation. setuptools.build_meta is indeed already installed, but
# setuptools_scm is not, and this package's version comes ONLY from setuptools_scm
# (there is no static `version =` anywhere in setup.py or setup.cfg). Built without
# it the wheel still succeeds -- and silently records the version as 0.0.0. That
# produced /usr/lib/python3.14/site-packages/python_dateutil-0.0.0.dist-info here,
# so `pip install` of any dependent that pins a floor rejected it as too old:
# blfs-recurring-ical-events failed outright with "Could not find a version that
# satisfies the requirement python-dateutil<3.0.0,>=2.8.1 (from versions: none)"
# despite dateutil being importable and working. lfsmaint's own DB read
# 2.9.0.post0 the whole time, because that is the title in packages.py, not
# anything measured off the install.
#
# Fix: leave build isolation ON so pip fetches setuptools_scm<8.0 into a throwaway
# build env, same as icalendar/vdirsyncer/khal already do for hatchling. With no
# .git in a release sdist setuptools_scm falls back to the sdist's own PKG-INFO,
# verified to produce python_dateutil-2.9.0.post0-py2.py3-none-any.whl and not a
# 0.0.0 placeholder.
#
# --upgrade on the install line: on a fresh system this is a plain install, but on
# a host that already has the broken 0.0.0 recorded, pip considers the bare
# requirement `python-dateutil` already satisfied and does nothing. --upgrade is
# what makes this recipe able to repair its own earlier output. --no-index
# --find-links dist means the only candidate it can ever choose is the wheel built
# on the line above.
set -e

pip3 wheel -w dist --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user --upgrade python-dateutil

echo "### installed version (must not be 0.0.0 -- see the header)"
pip3 show python-dateutil | grep '^Version:'
