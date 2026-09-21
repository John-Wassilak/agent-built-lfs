#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/geoclue2.html
# title  : GeoClue-2.8.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: -2.8.0.tar.bz2 Download MD5 sum: def58282c7e1c95bc386906fdfbe29e3 Download size: 112 KB
#   ctx: Estimated disk space required: 7.4 MB Estimated build time: 0.1 SBU GeoClue Dependencies
#   ctx: Required JSON-GLib-1.10.8 and libsoup-3.6.6 Recommended libnotify-0.8.8,
#   ctx: ModemManager-1.24.2, and Vala-0.56.18 Optional Avahi-0.8 and GTK-Doc-1.35.1 Installation
#   ctx: of GeoClue Install GeoClue by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr        \
            --buildtype=release  \
            -D gtk-doc=false     \
            -D nmea-source=false \
            ..                   &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: I key must be used, and a configuration file must be created. This API key is only
#   ctx: intended for use with LFS. Please do not use this API key if you are building for
#   ctx: another distro or distributing binary copies. If you need an API key, you can request
#   ctx: one at https://www.chromium.org/developers/how-tos/api-keys. Create the configuration
#   ctx: needed for using Google's Geolocation Service as the root user:
#   REVIEWED [drop]: The book writes /etc/geoclue/conf.d/90-lfs-google.conf pointing the [wifi] source at Google's Geolocation Service with the key the Firefox page also uses, and that key is dead: a direct POST to https://www.googleapis.com/geolocation/v1/geolocate with it returns '403 PERMISSION_DENIED: You must enable Billing on the Google Cloud Project' (re-verified 2026-09-08, and again against the current development book r13.1-84, which still ships the same key on both pages). Writing the file is worse than skipping it: GeoClue-2.8.0's own compile-time default for that same setting is already https://api.beacondb.net/v1/geolocate (meson_options.txt, 'default-wifi-url'), keyless and public-domain, and the book's file overrides that good default with a dead endpoint. beaconDB is the Ichnaea-compatible successor to the Mozilla Location Service Mozilla shut down in June 2024, and pointing GeoClue at it is what Gentoo, Fedora, NixOS, Guix and Void all do. Dropping the block therefore leaves the stock upstream configuration in place -- no conf.d file, no key, no third party the book has to keep paying for. This is a book fact, not a machine fact, so the decision is shared: any host building this page is better off without the file. Coverage is a separate question and is per-location -- see hosts/laptop/BUILD-REPORT.md and PRACTICES.md for what beaconDB actually answers here.
# cat > /etc/geoclue/conf.d/90-lfs-google.conf << "EOF"
# # Begin /etc/geoclue/conf.d/90-lfs-google.conf
# 
# # This configuration applies for the WiFi source.
# [wifi]
# 
# # Set the URL to Google's Geolocation Service.
# url=https://www.googleapis.com/geolocation/v1/geolocate?key=AIzaSyDxKL42zsPjbke5O8_rPVpVrLrJ8aeE9rQ
# 
# # End /etc/geoclue/conf.d/90-lfs-google.conf
# EOF

