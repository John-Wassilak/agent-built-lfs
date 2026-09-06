#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/redland.html
# title  : Redland-1.0.17
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: f.org/source/redland-1.0.17.tar.gz Download MD5 sum: e5be03eda13ef68aabab6e42aa67715e
#   ctx: Download size: 1.6 MB Estimated disk space required: 18 MB Estimated build time: 0.2 SBU
#   ctx: Redland Dependencies Required Rasqal-0.9.33 Optional MariaDB-11.8.6 or MySQL,
#   ctx: PostgreSQL-18.2, Berkeley DB (deprecated) libiodbc, virtuoso, and 3store Installation of
#   ctx: Redland Install Redland by running the following commands:
./configure --prefix=/usr --disable-static &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue make check. Now, as the root user:
make install

