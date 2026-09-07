#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-07): ifd-time-sync's
# lib/calendar_reader.py imports recurring_ical_events to expand RRULE-based
# recurring calendar events into concrete occurrences for a date range --
# icalendar (seq 278) parses the ICS but does not expand recurrences. Listed
# in that project's requirements.txt. Not in BLFS (general/python-modules.html
# covers a fixed set of modules on one page, not this closure). Pure-Python
# PyPI package, same pip3-wheel pattern as icalendar/khal.
# Build backend: hatchling>=1.27.0 + hatch-vcs (neither installed), so build
# isolation is left on and pip fetches both -- same as icalendar/vdirsyncer.
# hatch-vcs normally derives the version from git; with no .git in an sdist it
# falls back to the sdist's own PKG-INFO, verified locally to produce
# recurring_ical_events-3.8.2-py3-none-any.whl and not a 0.0.0 placeholder.
# Runtime deps (via --no-deps, all already installed as their own steps):
# icalendar (seq 278, <8.0.0 satisfied by 7.3.0), python-dateutil (seq 277),
# tzdata (LFS), x-wr-timezone (seq 310). backports-zoneinfo and
# typing-extensions are conditional on Python <= 3.9 and do not apply here
# (this host runs 3.14).
# Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against
# PyPI's own published digest:
#   e731af31d0b7dec5cd47a1defacd8549e2f36fab1c1995e8b9f042822a0acf8e
set -e

pip3 wheel -w dist --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user recurring-ical-events
