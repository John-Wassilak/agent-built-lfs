#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/pciutils.html
# title  : pciutils-3.14.0
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
