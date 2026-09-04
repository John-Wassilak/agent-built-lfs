#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. hyprshot's own dependency list names it ("to take the
# screenshot"). Moved upstream from GitHub to gitlab.freedesktop.org at v1.5.0 (its own
# release notes say so) -- fetched from there, matching Arch's own PKGBUILD source line
# (`git+https://gitlab.freedesktop.org/emersion/grim#tag=v1.5.0`). Arch builds this one
# from a git tag rather than a checksummed release tarball, so there is no independent
# packager hash to check this archive against; recorded here as this session's own
# sha256 of the GitLab tag archive, same class of gap already noted for enchant in
# BUILD-REPORT.md. Deps (cairo, wayland, pixman, libjpeg-turbo) were all already built
# for the GTK/mesa stack; man-pages and the bash/fish completions are all meson
# `feature: auto` options that quietly no-op without scdoc, which this host does not
# have and does not need just for this.
set -e

meson setup --prefix=/usr --buildtype=release . build
ninja -C build
ninja -C build install

echo "### version"
grim -h 2>&1 | head -1 || true
