#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for sdbus-c++.
# source: github.com/Kistler-Group/sdbus-cpp, tag v2.3.1 (2026-05-20)
# provenance: sha256 3a289eded586c26d06c1387de72c7bf7c809527a70d51ba6401fe61059b19626
# matches the sha256sums line in Arch's own sdbus-cpp PKGBUILD for the same 2.3.1 tag
# archive (gitlab.archlinux.org/archlinux/packaging/packages/sdbus-cpp), which is the
# cross-check this project uses for upstreams that publish no signature or checksum
# file of their own -- same pattern already used for oniguruma, slurp, wl-clipboard
# and the hypr* ecosystem.
#
# rationale: build dependency of xdg-desktop-portal-hyprland (seq 318), which requires
# sdbus-c++>=2.0.0 via pkg-config. XDPH's CMakeLists falls back to a bundled
# subprojects/sdbus-cpp when pkg-config finds nothing, but that fallback is a git
# submodule and a GitHub tag archive ships the directory empty (confirmed by
# inspection -- subprojects/sdbus-cpp exists and contains no files), so on this system
# the dependency is not optional: without this step XDPH cannot configure.
#
# A C++ binding layer over systemd's sd-bus, which is why it needs no new dependency
# here: libsystemd 259 is already the system's own, and SDBUSCPP_SDBUS_LIB defaults to
# searching for it. Portable, nothing host-specific -- shared recipe.
set -e

# Only the library, which is all XDPH links against. Every option below is set
# explicitly rather than left to its default, because two of the defaults would
# change what lands on this system:
#
#   SDBUSCPP_BUILD_LIBSYSTEMD=OFF   already the default, and it must stay off: ON
#                                   makes the build *download and compile its own
#                                   libsystemd* (SDBUSCPP_LIBSYSTEMD_VERSION 252) and
#                                   statically link it into libsdbus-c++, which on a
#                                   host whose libsystemd is 259 means shipping a
#                                   second, older, invisible copy of it.
#   SDBUSCPP_BUILD_DOCS=OFF         upstream's default is ON. It installs the
#                                   project's markdown documentation; the API
#                                   reference is online and nothing here reads it.
#   SDBUSCPP_BUILD_TESTS=OFF        the default. Left explicit because ON pulls
#                                   googletest from the network (its own
#                                   SDBUSCPP_GOOGLETEST_GIT_REPO) when gmock is not
#                                   installed, which it is not here.
#   SDBUSCPP_BUILD_CODEGEN=OFF      the default. The sdbus-c++-xml2cpp generator is a
#                                   development tool for producing bindings from D-Bus
#                                   introspection XML; XDPH ships its own hand-written
#                                   bindings and does not use it.
cmake -B build -S . \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D SDBUSCPP_BUILD_LIBSYSTEMD=OFF \
      -D SDBUSCPP_BUILD_DOCS=OFF \
      -D SDBUSCPP_BUILD_TESTS=OFF \
      -D SDBUSCPP_BUILD_CODEGEN=OFF
cmake --build build
cmake --install build

install -v -d /usr/share/licenses/sdbus-c++
install -v -m644 COPYING* /usr/share/licenses/sdbus-c++/

echo "### version"
pkg-config --modversion sdbus-c++
