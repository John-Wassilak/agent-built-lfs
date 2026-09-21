#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/curl.html
# title  : cURL-8.18.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: p2-1.68.0, OpenLDAP-2.6.12, Samba-4.23.5 (runtime, for NTLM authentication), gsasl,
#   ctx: impacket, libmetalink, librtmp, ngtcp2, quiche, and SPNEGO Optional if Running the Test
#   ctx: Suite Apache-2.4.66 and stunnel-5.77 (for the HTTPS and FTPS tests), OpenSSH-10.2p1, and
#   ctx: Valgrind-3.26.0 (this will slow the tests down and may cause failures) Installation of
#   ctx: cURL Install cURL by running the following commands:
./configure --prefix=/usr    \
            --disable-static \
            --with-openssl   \
            --with-ca-path=/etc/ssl/certs &&
make

# --- block 1 --------------------------------------------------
#   ctx: e tests are flaky, so if some tests have failed it's possible to run a test again with:
#   ctx: (cd tests; ./runtests.pl <test ID>) (the ID of failed tests are shown in the “These test
#   ctx: cases failed:” message). If you run the tests after the package has been installed, some
#   ctx: tests may fail because the man pages were deleted by the 'find' command in the
#   ctx: installation instructions below. Now, as the root user:
make install &&

rm -rf docs/examples/.deps &&

find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete &&

cp -v -R docs -T /usr/share/doc/curl-8.18.0

