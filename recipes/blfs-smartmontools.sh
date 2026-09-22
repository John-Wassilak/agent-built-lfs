#!/bin/bash
# HAND-AUTHORED recipe, shared (belongs to no book release).
# source : postlfs/smartmontools.html, read against both 13.0 and 13.1 on 2026-09-22.
# title  : smartmontools-7.5
#
# Both releases pin 7.5 and their command sets match, so the versioned --docdir below
# is correct for either and this file stays shared. If the two books ever diverge on
# this package the docdir makes it release-bound, and it has to become a host copy --
# the same reasoning as blfs-wireplumber.
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
