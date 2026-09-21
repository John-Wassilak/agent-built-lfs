#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/chroot.html
# title  : 7.4. Entering the Chroot Environment
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Now that all the packages which are required to build the rest of the needed tools are
#   ctx: on the system, it is time to enter the chroot environment and finish installing the
#   ctx: temporary tools. This environment will also be used to install the final system. As user
#   ctx: root, run the following command to enter the environment that is, at the moment,
#   ctx: populated with nothing but temporary tools:
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login

