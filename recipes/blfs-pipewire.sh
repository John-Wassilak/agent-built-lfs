#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/pipewire.html
# title  : pipewire-1.6.0
# rationale: Operator-requested, queued before Firefox. Built with just its
# core Recommended dep already present (PulseAudio, tier 11) -- the rest of
# the Recommended list (BlueZ, gstreamer, SBC, v4l-utils) is Bluetooth/video-
# capture/GStreamer integration this box has no current use for; skipped per
# the standing "verify it actually fits" policy rather than built
# reflexively. Wireplumber (its session manager) is the very next package in
# this same tier -- pipewire alone has no automatic device management.
# session-managers=[] because Wireplumber, not pipewire's old built-in
# media-session, is what actually gets configured.
#
# -D alsa=enabled added 2026-09-04, after this package was found to have
# installed no ALSA support at all on laptop. Every meson `feature` option here
# defaults to `auto`, so pipewire quietly built and installed with no
# /usr/lib/spa-0.2/alsa/libspa-alsa.so, exiting 0 with nothing in the log to
# read as a failure. The consequence only shows up two packages later and
# nowhere near the cause: pipewire and wireplumber both start and stay running,
# `pw-cli info 0` answers normally, and `wpctl status` lists a healthy graph
# with zero Devices/Sinks/Sources -- wireplumber's own log is the only place
# that names it ("SPA handle 'api.alsa.enum.udev' could not be loaded",
# "PipeWire's ALSA SPA plugin is missing or broken. Sound cards will not be
# supported"). Root cause was build ORDER, not this recipe: pipewire was seq
# 123 and alsa-lib seq 130, so alsa-lib did not exist yet when meson probed for
# it (see the seq note in hosts/laptop/packages.py). The ordering is fixed
# there; `enabled` rather than `auto` is here so that if it ever regresses the
# build fails loudly at configure time instead of shipping a silently mute
# system. Any machine running this book wants both halves.
#
# -D bluez5=enabled added 2026-09-04 (operator-requested Bluetooth audio), and it
# is `enabled` for the same reason alsa is -- with `auto` a missing dependency
# silently drops Bluetooth audio. Unlike alsa, this one has a real dependency set,
# read out of spa/meson.build rather than guessed:
#
#     bluez_dep = dependency('bluez', version : '>= 4.101', required: get_option('bluez5'))
#     sbc_dep   = dependency('sbc', required: get_option('bluez5'))
#     bluez5_deps = [ mathlib, dbus_dep, sbc_dep, bluez_dep, bluez_glib2_dep,
#                     bluez_gio_dep, bluez_gio_unix_dep ]
#     foreach dep: bluez5_deps
#         if get_option('bluez5').enabled() and not dep.found()
#           error('bluez5 enabled, but dependency not found: ' + dep.name())
#
# So `enabled` makes ALL of bluez, sbc, dbus and glib/gio hard requirements, and a
# missing one is a loud configure error. Careful reading a second probe in
# spa/plugins/bluez5/meson.build:
#     cdata.set('HAVE_BLUEZ_5_HCI', dependency('bluez', version: '< 6', required: false).found())
# that one is `required: false`, but it only sets HAVE_BLUEZ_5_HCI -- it is not the
# dependency gate, and mistaking it for one (as happened here first time round)
# leads to the wrong conclusion that bluez need not be built before pipewire.
#
# Consequence for build order: bluez and sbc must both precede this step. They do
# now -- hosts/laptop/packages.py moved libical/bluez to seq 130.1/130.2 and put
# sbc at 130.3, all ahead of pipewire's 130.5, specifically so `enabled` can hold.
# Do not reorder pipewire earlier without moving those too.
#
# Codecs beyond SBC (LDAC, aptX, LC3, FDK-AAC) are left to their own `auto`
# options, which is correct here: they are genuinely optional extra codecs, none is
# built, and their absence costs only codec choice on a connected device, not
# Bluetooth audio itself. That is the case `auto` is actually for.
set -e

mkdir build
cd build

meson setup .. \
  --prefix=/usr \
  --buildtype=release \
  -D session-managers="[]" \
  -D alsa=enabled \
  -D bluez5=enabled
ninja

ninja install

echo "### pkg-config"
pkg-config --modversion libpipewire-0.3 2>&1 || true
