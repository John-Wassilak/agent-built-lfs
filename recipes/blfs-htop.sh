#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in the BLFS 13.0 book (checked: no book/blfs-13.0 page mentions it). Checked AUR first per the two-tier sourcing policy (BLFS when possible, else another distro's packaging as a build reference) -- zero AUR results, because htop is popular enough to live in Arch's official 'extra' repo instead. Build recipe below is adapted from Arch's real PKGBUILD (gitlab.archlinux.org/archlinux/packaging/packages/htop), cross-checked against htop's own configure.ac rather than trusted blindly: --enable-sensors and --enable-delayacct need lm_sensors and libnl-3, neither installed here and neither worth a separate package for two optional features that auto-disable cleanly without them; --enable-openvz and --enable-vserver are in Arch's flag list but do not exist as options in this htop version at all (dead flags, dropped here rather than copied). --enable-capabilities (libcap) and --enable-unicode (ncursesw) are kept -- both already present from the base LFS build.
set -e

HTOP_VER=3.5.3
rm -rf htop
git clone --branch "$HTOP_VER" --depth 1 https://github.com/htop-dev/htop.git
cd htop
autoreconf -fi
./configure --prefix=/usr \
            --sysconfdir=/etc \
            --enable-affinity \
            --enable-capabilities \
            --enable-unicode
make
make install

echo "### version"
htop --version

