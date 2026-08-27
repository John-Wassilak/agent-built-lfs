#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libxdg-basedir.
# source: github.com/devnev/libxdg-basedir, tag libxdg-basedir-1.2.3.
# Rationale: awesome window manager dependency (see AWESOME-X11-PLAN.md).
set -e

autoreconf -fi
./configure --prefix=/usr --disable-static
make
make install
