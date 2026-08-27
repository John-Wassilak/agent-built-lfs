#!/bin/bash
# HAND-AUTHORED recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/smartmontools.html
# title  : smartmontools-7.5
# rationale: no hard BLFS dependencies beyond what's already built.
# Added 2026-08-27 during a hardware/runtime audit -- disk health
# (SMART status) was a blind spot with no tooling installed to check
# it at all.
set -e

./configure --prefix=/usr \
  --sysconfdir=/etc \
  --docdir=/usr/share/doc/smartmontools-7.5
make
make install
