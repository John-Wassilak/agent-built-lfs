#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libsoup3.html
# title  : libsoup-3.6.6
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: otli-1.2.0, cURL-8.18.0 (required to run the test suite), Gi-DocGen-2026.1, MIT Kerberos
#   ctx: V5-1.22.2 (required to run the test suite), PHP-8.5.3 compiled with XMLRPC-EPI support
#   ctx: (only used for the XMLRPC regression tests), Samba-4.23.5 (ntlm_auth is required to run
#   ctx: the test suite), sysprof, and wstest Installation of libsoup3 First, fix a security
#   ctx: vulnerability that could lead to credential leakage:
patch -Np1 -i ../libsoup-3.6.6-upstream_fixes-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Fix the installation path of API documentation:
sed 's/apiversion/soup_version/' -i docs/reference/meson.build

# --- block 2 --------------------------------------------------
#   ctx: Install libsoup3 by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr          \
            --buildtype=release    \
            --wrap-mode=nofallback \
            ..                     &&
ninja

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install

