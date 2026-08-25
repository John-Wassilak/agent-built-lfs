#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/changingowner.html
# title  : 7.2. Changing Ownership
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: under $LFS are kept as they are, they will be owned by a user ID without a
#   ctx: corresponding account. This is dangerous because a user account created later could get
#   ctx: this same user ID and would own all the files under $LFS, thus exposing these files to
#   ctx: possible malicious manipulation. To address this issue, change the ownership of the
#   ctx: $LFS/* directories to user root by running the following command:
chown --from lfs -R root:root $LFS/{usr,var,etc,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac

