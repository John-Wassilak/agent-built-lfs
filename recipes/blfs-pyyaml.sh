#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Same situation as blfs-mako. Required by Mesa's build-time code generation scripts. Its own Recommended deps (cython, libyaml, for C-accelerated parsing) skipped -- one-level policy, and this is a build-time tool only.
set -e

pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user PyYAML

