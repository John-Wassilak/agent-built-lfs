#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/liblinear.html
# title  : liblinear-250
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: need to reinstall Nmap-7.98 in order to link to the new library. Package Information
#   ctx: Download (HTTP): https://github.com/cjlin1/liblinear/archive/v250/liblinear-250.tar.gz
#   ctx: Download MD5 sum: 53ffb394295c7f766adc200a603d6e0d Download size: 76 KB Estimated disk
#   ctx: space required: 712 KB Estimated build time: less than 0.1 SBU Installation of liblinear
#   ctx: Install liblinear by running the following commands:
make lib

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
install -vm644 linear.h /usr/include   &&
install -vm755 liblinear.so.6 /usr/lib &&
ln -sfv liblinear.so.6 /usr/lib/liblinear.so

