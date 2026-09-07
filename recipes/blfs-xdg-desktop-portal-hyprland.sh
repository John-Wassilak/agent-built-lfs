#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for xdg-desktop-portal-hyprland.
# source: github.com/hyprwm/xdg-desktop-portal-hyprland, tag v1.4.1 (2026-07-29)
# provenance: sha256 3652c14f63a9666acea2c841e196782dbc0f74ea5b4783622dd04a32f08b709f
# matches Arch's own xdg-desktop-portal-hyprland PKGBUILD for the same 1.4.1 tag
# archive, which also confirms 1.4.1 is the currently packaged release rather than a
# tag nobody ships. Same cross-check pattern as the rest of the hypr* steps here.
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
#                                                 was the reported symptom. Qt6
#                                                 Widgets app; /opt/qt6 has both
#                                                 Widgets and WaylandClient, checked
#                                                 before building.
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
#     >=2.0.0 is built at seq 317, and hyprland-protocols 0.7.0 at seq 114 already
#     supplies all four XML files this version compiles bindings from
#     (hyprland-global-shortcuts-v1, hyprland-toplevel-export-v1,
#     hyprland-toplevel-mapping-v1, hyprland-input-capture-v1 -- checked against the
#     installed /usr/share/hyprland-protocols/protocols). Arch's PKGBUILD pins an
#     extra hyprland-protocols commit tarball into that subproject directory; ignored
#     here deliberately, because that commit contains only two of the four XMLs and is
#     therefore older than the release this host already has -- CMake prefers the
#     pkg-config copy anyway.
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

# Qt6 lives in /opt/qt6 on this system (BLFS's own recommended prefix). CMake finds it
# without an explicit CMAKE_PREFIX_PATH because /etc/profile.d/qt6.sh puts
# /opt/qt6/bin on PATH and CMake searches the parent of every PATH entry -- the same
# mechanism blfs-quickshell.sh relies on, and the driver runs recipes under
# `bash --login` so profile.d is sourced. Asserted rather than assumed: a missing Qt6
# would otherwise fail deep inside the share-picker subdirectory.
test -d /opt/qt6/lib/cmake/Qt6Widgets || {
    echo "Qt6 Widgets not found under /opt/qt6 -- hyprland-share-picker cannot build" >&2
    exit 1
}

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
