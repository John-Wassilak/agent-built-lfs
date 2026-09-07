#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-07): dependency closure for the
# ifd-time-sync tool (Harvest/Jira/calendar time entry), which imports
# recurring_ical_events -- x-wr-timezone is that package's own hard runtime
# dependency ('x-wr-timezone >= 1.0.0, < 3.0.0' in its pyproject.toml).
# Repairs Google Calendar's non-RFC-5545 X-WR-TIMEZONE property, which is
# exactly what the ICS feeds ifd-time-sync reads are exported with.
# Not in BLFS (general/python-modules.html covers a fixed set of modules on
# one page, not this closure). Pure-Python PyPI package, same pip3-wheel
# pattern as icalendar/python-dateutil.
# Build backend: legacy setup.py/setup.cfg, no pyproject.toml -- setuptools
# (already present) handles it directly, hence --no-build-isolation.
# Runtime deps (via --no-deps, all already installed as their own steps):
# icalendar (seq 278), tzdata (LFS), click (seq 266).
# Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against
# PyPI's own published digest:
#   9166c40e6ffd4c0edebabc354e1a1e2cffc1bb473f88007694793757685cc8c3
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user x-wr-timezone
