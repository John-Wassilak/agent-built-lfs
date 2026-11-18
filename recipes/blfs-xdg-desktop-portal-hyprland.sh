#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xdg-desktop-portal-hyprland.
# source: github.com/hyprwm/xdg-desktop-portal-hyprland, tag v1.5.0 (2026-10-28)
# provenance: sha256 8f9eddad706b0bbca2dc24f9894e07969ec5aed163249d6eac3932cfaf38e6a9
# matches Arch's own xdg-desktop-portal-hyprland PKGBUILD for the same 1.5.0 tag
# archive. Same cross-check pattern as the rest of the hypr* steps here.
#
# 1.4.1 -> 1.5.0 on laptop, 2026-11-18. A window share went into a renegotiation
# loop ("Out of buffers", "Retrying screencopy", "Incompatible formats, renegotiate
# stream") and the pipewire 1.6.0 daemon aborted under it. 1.5.0 carries the upstream
# fixes for that loop: PR #424 (out-of-buffers path destroyed its own new frame
# callback and reallocated the buffer pool on every retry), PR #425 (same re-entrancy
# in the format-mismatch branch) and PR #447 (u32 underflow building the DMA-BUF
# modifier list).
#
# What changed in the build for 1.5.0, read from its CMakeLists.txt files:
#   - hyprland-share-picker is no longer Qt6. It is a hyprtoolkit app and requires
#     hyprtoolkit >= 0.6.0, hyprutils >= 0.2.6 and libdrm. The old Qt6 assertion is
#     gone from this recipe because nothing here uses Qt any more.
#   - hyprland-protocols >= 0.8.0 is required, and CMake stops if
#     hyprland-workspace-image-capture-source-v1.xml is missing. 0.8.0 is the first
#     release that ships it.
#   - Four more wayland-protocols staging XMLs are compiled in: ext-foreign-
#     toplevel-list, ext-image-copy-capture, ext-image-capture-source, ext-workspace.
#     All four are in wayland-protocols 1.49 here.
#
# rationale: THIS is the package that makes screen sharing work under Hyprland, and
# the reason it was missing was diagnosed live (2026-09-07, laptop): Google Meet in
# Firefox reported a permissions failure with no picker ever appearing. BLFS carries
# xdg-desktop-portal (seq 315) and lists only the gtk/gnome/lxqt backends, and none of
# those implements the ScreenCast portal for a wlroots-style compositor -- the GNOME
# one drives Mutter, the GTK one has no ScreenCast at all. On Hyprland the ScreenCast
# (and Screenshot, and GlobalShortcuts) implementation is this separate project.
#
# What it installs and why each piece matters:
#   /usr/libexec/xdg-desktop-portal-hyprland      the backend daemon
#   /usr/bin/hyprland-share-picker                the "what do you want to share?"
#                                                 dialog -- the popup whose absence
#                                                 was the reported symptom. A Qt6
#                                                 Widgets app through 1.4.1, a
#                                                 hyprtoolkit app from 1.5.0.
#   /usr/share/xdg-desktop-portal/portals/hyprland.portal
#                                                 declares which portal interfaces
#                                                 this backend implements
#   /usr/share/dbus-1/services/org.freedesktop.impl.portal.desktop.hyprland.service
#                                                 D-Bus activation, so nothing has to
#                                                 start it by hand
#   /usr/lib/systemd/user/xdg-desktop-portal-hyprland.service
#                                                 from SYSTEMD_SERVICES (ON by
#                                                 default) -- the unit this host's
#                                                 own hyprland.lua already restarts
#                                                 at session start
#
# Nothing here is host-specific (no GPU, disk or display name), so this is a shared
# recipe even though laptop is currently the only machine with a Wayland session.
#
# Dependency notes, all verified live before the first build rather than assumed:
#   - The tag archive's subprojects/hyprland-protocols and subprojects/sdbus-cpp are
#     git submodules and arrive EMPTY. XDPH's CMakeLists uses them only as a fallback
#     when pkg-config finds nothing, so both must come from the system: sdbus-c++
#     >=2.0.0 is built at seq 317, and hyprland-protocols at seq 114 must be 0.8.0 or
#     later for 1.5.0 (see above). Arch's PKGBUILD pins an extra hyprland-protocols
#     commit tarball into that subproject directory; ignored here deliberately, because
#     CMake prefers the pkg-config copy whenever it is new enough.
#   - No --prefix games with libexec: GNUInstallDirs' default puts the daemon in
#     ${prefix}/libexec, which is /usr/libexec and matches both BLFS's own
#     xdg-desktop-portal layout ("several daemons in /usr/libexec") and the path this
#     host's hyprland.lua already invokes. Arch overrides it to /usr/lib for its own
#     distro convention; that would be wrong here.
#   - grim 1.5.0 and slurp 1.5.0 (seq 240/241) are already installed. XDPH warns at
#     startup and disables parts of the Screenshot portal without them
#     (src/core/PortalManager.cpp checks both on PATH), so the screenshot portal comes
#     up complete on this host.
set -e

cmake -B build -S . \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build

install -v -d /usr/share/licenses/xdg-desktop-portal-hyprland
install -v -m644 LICENSE /usr/share/licenses/xdg-desktop-portal-hyprland/LICENSE

echo "### version"
/usr/libexec/xdg-desktop-portal-hyprland --version 2>&1 | head -2 || true
echo "### installed portal declaration"
cat /usr/share/xdg-desktop-portal/portals/hyprland.portal
