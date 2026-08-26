#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/fdk-aac.html
# title  : fdk-aac-2.0.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: own to build and work properly using an LFS 13.0 platform. Package Information Download
#   ctx: (HTTP): https://downloads.sourceforge.net/opencore-amr/fdk-aac-2.0.3.tar.gz Download MD5
#   ctx: sum: f43e593991caefdce509ad837d3301bd Download size: 2.8 MB Estimated disk space
#   ctx: required: 39 MB Estimated build time: 0.6 SBU (Using parallelism=4) Installation of
#   ctx: fdk-aac Install fdk-aac by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

