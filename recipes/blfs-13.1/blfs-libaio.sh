#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/libaio.html
# title  : libaio-0.3.113
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e This package is known to build and work properly using an LFS 13.1 platform. Package
#   ctx: Information Download (HTTP): https://releases.pagure.org/libaio/libaio-0.3.113.tar.gz
#   ctx: Download MD5 sum: 7d5be185f20eeaae15e267419950aaf7 Download size: 52 KB Estimated disk
#   ctx: space required: 1.1 MB Estimated build time: less than 0.1 SBU Installation of libaio
#   ctx: First, disable the installation of the static library:
sed -i '/install.*libaio.a/s/^/#/' src/Makefile

# --- block 1 --------------------------------------------------
#   ctx: Next, fix an issue in the test suite:
case "$(uname -m)" in
  i?86) sed -e "s/off_t/off64_t/" -i harness/cases/23.t ;;
esac

# --- block 2 --------------------------------------------------
#   ctx: Build libaio by running the following command:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: make partcheck. Now, install the package as the root user:
make install

