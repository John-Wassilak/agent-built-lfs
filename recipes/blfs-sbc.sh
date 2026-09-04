#!/bin/bash
# HAND-AUTHORED recipe -- not carried by the BLFS 13.0 book (checked: no sbc page,
# and no sbc tarball in the book's source set).
#
# rationale: SBC is the mandatory A2DP codec, and pipewire's `bluez5` meson feature
# will not build without it. Read pipewire-1.6.0/spa/meson.build directly rather
# than guessing which deps are optional -- it is explicit:
#
#     bluez_dep = dependency('bluez', version : '>= 4.101', required: get_option('bluez5'))
#     sbc_dep   = dependency('sbc', required: get_option('bluez5'))
#     bluez5_deps = [ mathlib, dbus_dep, sbc_dep, bluez_dep, bluez_glib2_dep,
#                     bluez_gio_dep, bluez_gio_unix_dep ]
#     foreach dep: bluez5_deps
#         if get_option('bluez5').enabled() and not dep.found()
#           error('bluez5 enabled, but dependency not found: ' + dep.name())
#
# so with -D bluez5=enabled every one of those is required and a missing one is a
# hard configure error, not a silent downgrade. (A separate probe in
# spa/plugins/bluez5/meson.build uses `required: false`, but that one only sets
# HAVE_BLUEZ_5_HCI -- it is not the dependency gate. Easy to misread; it was
# misread once here before checking.) That is why sbc, bluez and libical all sit
# ahead of pipewire in seq -- see hosts/laptop/packages.py.
#
# Source: kernel.org's bluetooth release directory, upstream for the BlueZ
# project's own libraries. Shared, not host-specific: a portable audio codec
# library with nothing machine-dependent in it.
#   sbc-2.1.tar.xz
#   sha256 426633cabd7c798236443516dfa8335b47e004b0ef37ff107e0c7ead3299fcc2
#
# Options, from `./configure --help` on this exact tarball rather than copied from
# a distro packaging script:
#   --disable-static  matches how every other library in this build is installed.
#   --disable-tester  the tester links libsndfile and only exists to run
#                     encode/decode comparisons; nothing here consumes it.
# Tools (sbcenc/sbcdec) are left enabled -- they are tiny and genuinely useful for
# checking a codec problem by hand.
set -e

./configure --prefix=/usr \
            --disable-static \
            --disable-tester
make

make install

echo "### pkg-config"
pkg-config --modversion sbc 2>&1 || true
