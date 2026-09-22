#!/bin/bash
# HAND-AUTHORED recipe, shared (belongs to no book release).
# source : general/pciutils.html, read against both 13.0 and 13.1 on 2026-09-22.
# title  : pciutils (version comes from the host's own packages.py pin)
#
# The two releases' command sets are identical -- the Makefile sed, the two make
# invocations and the libpci.so chmod are byte-equal apart from the book's own
# whitespace alignment -- and nothing here names a version, which is what keeps this
# file legitimately shared. `server` builds 3.15.0 from it (BLFS 13.1) and `laptop`
# 3.14.0 (BLFS 13.0), off the same commands.
# rationale: Operator-requested diagnostic tooling (lspci) -- flagged as
# missing during the post-outage system scan. Recommended: hwdata (already
# built, tier 2) -- pci.ids installation deliberately disabled here in favor
# of hwdata's own copy, per the book's own conflict-avoidance instruction.
set -e

sed -r '/INSTALL/{/PCI_IDS|update-pciids /d; s/update-pciids.8//}' -i Makefile

make PREFIX=/usr \
  SHAREDIR=/usr/share/hwdata \
  SHARED=yes

make PREFIX=/usr \
  SHAREDIR=/usr/share/hwdata \
  SHARED=yes \
  install install-lib
chmod -v 755 /usr/lib/libpci.so

echo "### version"
lspci --version 2>&1 || true
