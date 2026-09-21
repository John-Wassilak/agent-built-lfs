#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/bubblewrap.html
# title  : Bubblewrap-0.11.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of Bubblewrap Install Bubblewrap by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: Next, if you desire to run the test suite, fix an issue caused by the merged-/usr
#   ctx: configuration in LFS:
#   REVIEWED [drop]: Book's own text is conditional on running the test suite: 'Next, if you desire to run the test suite, fix an issue caused by the merged-/usr configuration in LFS'. The sed only patches tests/libtest.sh, so it changes nothing that gets installed, and the test suite itself is skipped here the same way every other optional test block in this project is -- Bubblewrap's tests need libseccomp built with its python bindings (Optional on the page), which is not in this build's closure. True of any host building bubblewrap without libseccomp.
# sed 's@symlink usr/lib64@ro-bind-try /lib64@' -i ../tests/libtest.sh

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue (as a user other than the root user): ninja test Now, as the
#   ctx: root user:
ninja install

