#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/iana-etc.html
# title  : 8.4. Iana-Etc-20260202
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The Iana-Etc package provides data for network services and protocols. Approximate build
#   ctx: time: less than 0.1 SBU Required disk space: 4.8 MB 8.4.1. Installation of Iana-Etc For
#   ctx: this package, we only need to copy the files into place:
cp -v services protocols /etc

