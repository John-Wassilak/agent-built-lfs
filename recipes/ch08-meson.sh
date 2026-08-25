#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/meson.html
# title  : 8.59. Meson-1.10.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Meson is an open source build system designed to be both extremely fast and as user
#   ctx: friendly as possible. Approximate build time: less than 0.1 SBU Required disk space: 48
#   ctx: MB 8.59.1. Installation of Meson Compile Meson with the following command:
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# --- block 1 --------------------------------------------------
#   ctx: The test suite requires some packages outside the scope of LFS. Install the package:
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

