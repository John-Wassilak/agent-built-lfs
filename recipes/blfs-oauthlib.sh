#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Operator-requested (2026-09-05): vdirsyncer's Google OAuth storage
# needs the "google" extra (aiohttp-oauthlib), which this project's khal/
# vdirsyncer closure deliberately skipped as an optional extra -- turned out to be
# required in practice (`vdirsyncer sync` failed live: "aiohttp-oauthlib not
# installed"). oauthlib is aiohttp-oauthlib's own only unconditional dependency
# (its other requires_dist entries are all extras: rsa, signedtoken, signals).
# Legacy setup.py/setup.cfg, no pyproject.toml -- setuptools (already present)
# handles it directly, same --no-build-isolation pattern as pyyaml/mako.
# Sourced via `pip3 download --no-binary :all: --no-deps`, not a hand-rolled PyPI
# JSON fetch -- sha256 matches PyPI's own published digest for the 3.3.1 sdist.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user oauthlib
