#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/sshfs.html
# title  : sshfs-3.7.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: eleases/download/sshfs-3.7.5/sshfs-3.7.5.tar.xz Download MD5 sum:
#   ctx: 5d9d4575d5c0b535857f41f723e92c85 Download size: 52 KB Estimated disk space required: 0.9
#   ctx: MB Estimated build time: less than 0.1 SBU Sshfs Dependencies Required Fuse-3.18.1,
#   ctx: GLib-2.86.4, and OpenSSH-10.2p1. Optional docutils-0.22.4 (required to build the man
#   ctx: page) Installation of Sshfs Install Sshfs by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: Using Sshfs To mount an ssh server you need to be able to log into the server. For
#   ctx: example, to mount your remote home folder to the local ~/examplepath (the directory must
#   ctx: exist and you must have permissions to write to it):
#   REVIEWED [drop]: 'Using Sshfs' usage example ('To mount an ssh server you need to be able to log into the server... sshfs example.com:/home/userid ~/examplepath') -- a literal demo command from the book's usage section, not part of installation. Running it during the build would try to actually SSH to example.com and either hang on a password prompt or fail outright.
# sshfs example.com:/home/userid ~/examplepath

# --- block 3 --------------------------------------------------
#   ctx: When you've finished work and want to unmount it again:
#   REVIEWED [drop]: The matching 'fusermount3 -u ~/examplepath' unmount example for the demo mount above -- same usage-example block, not installation. Nothing to unmount since block 2's mount never ran.
# fusermount3 -u ~/examplepath

