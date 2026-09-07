#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-05): vdirsyncer's Google OAuth storage
# needs this ("google" extra) -- `vdirsyncer sync` failed live: "aiohttp-oauthlib
# not installed". Its own two deps (oauthlib, aiohttp) are separate steps in this
# same closure. Legacy setup.py/setup.cfg, no pyproject.toml.
# Sourced via `pip3 download --no-binary :all: --no-deps`, not a hand-rolled PyPI
# JSON fetch -- sha256 matches PyPI's own published digest for the 0.1.0 sdist.
#
# Version fix 2026-09-07 (laptop), same defect and same one-flag fix as
# blfs-python-dateutil.sh, found in the same pass: setup.py takes its version
# solely from `use_scm_version` + `setup_requires=["setuptools_scm"]`, and
# setuptools_scm is not installed on this system. Under the original
# --no-build-isolation that requirement went unsatisfied, the wheel built anyway,
# and the version was recorded as 0.0.0 --
# /usr/lib/python3.14/site-packages/aiohttp_oauthlib-0.0.0.dist-info. Nothing
# depends on a version floor here (vdirsyncer's "google" extra names
# aiohttp-oauthlib unversioned), so unlike dateutil this never broke a build --
# it just made the recorded version a lie. With build isolation left on, the
# wheel comes out as aiohttp_oauthlib-0.1.0, verified locally.
#
# --upgrade for the same reason as blfs-python-dateutil.sh: a host already
# carrying the 0.0.0 install satisfies the bare requirement and would otherwise
# no-op.
set -e

pip3 wheel -w dist --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user --upgrade aiohttp-oauthlib

echo "### installed version (must not be 0.0.0 -- see the header)"
pip3 show aiohttp-oauthlib | grep '^Version:'
