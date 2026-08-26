#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libaio.html
# title  : libaio-0.3.113
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e is known to build and work properly using an LFS 13.0 platform. Package Information
#   ctx: Download (HTTP): https://pagure.io/libaio/archive/libaio-0.3.113/libaio-0.3.113.tar.gz
#   ctx: Download MD5 sum: 605237f35de238dfacc83bcae406d95d Download size: 48 KB Estimated disk
#   ctx: space required: 1.0 MB Estimated build time: less than 0.1 SBU Installation of libaio
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

