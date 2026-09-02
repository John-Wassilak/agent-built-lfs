#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/libevent.html
# title  : libevent-2.1.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: table/libevent-2.1.12-stable.tar.gz Download MD5 sum: b5333f021f880fe76490d8a799cd79f4
#   ctx: Download size: 1.0 MB Estimated disk space required: 20 MB (add 4 MB for tests and 4 MB
#   ctx: for API docs) Estimated build time: 0.3 SBU (add 11 SBU for tests) libevent Dependencies
#   ctx: Optional Doxygen-1.16.1 (for API documentation) Installation of libevent First, fix an
#   ctx: issue that prevents event_rpcgen.py from working:
sed -i 's/python/&3/' event_rpcgen.py

# --- block 1 --------------------------------------------------
#   ctx: Install libevent by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 2 --------------------------------------------------
#   ctx: If you have Doxygen-1.16.1 installed and wish to build API documentation, issue :
#   REVIEWED [drop]: 'If you have Doxygen installed and wish to build API documentation, issue: doxygen Doxyfile' -- doxygen is not part of this build; failed with 'doxygen: command not found', discovered when it did. Optional-dependency prose is not part of the extractor's classifier by design (keying off surrounding prose has caused real breakage before -- see PRACTICES.md), so this needs an explicit decision like every other doc-generation block in this build.
# doxygen Doxyfile

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue: make verify. Seven tests in every suite related to
#   ctx: regress_ssl.c and regress_http.c are known to fail due to incompatibilities with
#   ctx: OpenSSL-3. Some tests that are related to regress_dns.c are also known to fail
#   ctx: intermittently due to insufficient test timeouts. Now, as the root user:
make install

# --- block 4 --------------------------------------------------
#   ctx: If you built the API documentation, install it by issuing the following commands as the
#   ctx: root user:
#   REVIEWED [drop]: Installs the API documentation doxygen generated in block 2, which is dropped -- there is no doxygen/html/ directory to copy from.
# install -v -m755 -d /usr/share/doc/libevent-2.1.12/api &&
# cp      -v -R       doxygen/html/* \
#                     /usr/share/doc/libevent-2.1.12/api

