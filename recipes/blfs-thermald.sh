#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for thermald.
# source: github.com/intel/thermal_daemon, tag v2.5.12
# rationale: operator-requested, ThinkPad thermal management (fan/throttle
# tuning), matches what the live host actually runs. Not in BLFS. Deps
# checked against this project's own build: GLib, libxml2, libevdev all
# already present; UPower (required, book-covered) was not and is added
# alongside this as blfs-upower.sh.
set -e

# The release tag's source archive is a raw git snapshot (ships configure.ac
# but no pre-generated ./configure), so autoreconf must run -- and needs two
# patches, both verified against the real extracted source (autoreconf run
# to completion, then ./configure smoke-tested) before trusting them here.
#
# 1. configure.ac's one use of autoconf-archive (AX_CHECK_COMPILE_FLAG, for
#    -Wxxx/-std=c++11 flag detection) is guarded by m4_ifdef with a clean
#    AC_MSG_ERROR fallback if the macro is missing. Rather than pull in the
#    whole autoconf-archive package for one simple flag check, replaced
#    with a direct assignment of what it would have found anyway -- this
#    project's toolchain is a current GCC that supports every flag probed.
sed -i '/^m4_ifdef(\[AX_CHECK_COMPILE_FLAG\]/,/^\], \[AC_MSG_ERROR/c\
CXXFLAGS="$CXXFLAGS -std=c++11"' configure.ac
grep -q 'CXXFLAGS="\$CXXFLAGS -std=c++11"' configure.ac || {
    echo "thermald AX_CHECK_COMPILE_FLAG patch did not apply -- configure.ac structure changed" >&2
    exit 1
}

# 2. docs/ is pure gtk-doc API-doc generation (thermal_daemon-docs.xml,
#    version.xml.in -- confirmed by inspection, no man pages in it; the real
#    man pages live under man/ and install via man5_MANS/man8_MANS in the
#    top-level Makefile.am, unaffected by any of this). gtk-doc is not part
#    of this build (same doc-tool skip as every other package here), so
#    GTK_DOC_CHECK's unconditional use in configure.ac makes autoreconf fail
#    outright with 'gtkdocize failed' unless gtk-doc is installed. Dropped
#    docs/ from SUBDIRS and AC_CONFIG_FILES, and removed the GTK_DOC_CHECK
#    call -- confirmed no other file references gtk-doc.make once this is
#    done (grep, not assumed).
sed -i '/^GTK_DOC_CHECK/d' configure.ac
sed -i 's/^SUBDIRS = \. docs data/SUBDIRS = . data/' Makefile.am
perl -0777 -pi -e 's/AC_CONFIG_FILES\(\[Makefile\n\s*docs\/Makefile\n\s*docs\/version\.xml\n\s*data\/Makefile\]\)/AC_CONFIG_FILES([Makefile\n                 data\/Makefile])/' configure.ac
grep -q "GTK_DOC_CHECK" configure.ac && {
    echo "thermald GTK_DOC_CHECK removal did not apply -- configure.ac structure changed" >&2
    exit 1
}

mkdir -p m4
autoreconf -fi
# --sysconfdir=/etc, not autoconf's default of ${prefix}/etc: without it thermald
# installs its data files to /usr/etc/thermald/ and, more to the point, compiles that
# path in as TDCONFDIR and looks there at runtime. Found on laptop 2026-09-04 --
# `thermald[323]: Config file /usr/etc/thermald/thermal-conf.xml does not exist`,
# repeated four times at startup, with thermal-cpu-cdev-order.xml and
# thermald-features.xml sitting in /usr/etc/thermald alongside it. Self-consistent, so
# nothing was broken by it, but /usr/etc is not a directory this system otherwise has:
# it was the only package here that created one, and the operator-supplied
# thermal-conf.xml that overrides thermald's built-in thermal tables is exactly the file
# that would have been dropped in /etc/thermald and silently ignored.
./configure --prefix=/usr --sysconfdir=/etc --disable-werror
make
make install

echo "### version"
/usr/sbin/thermald --version 2>&1 | head -1 || true
