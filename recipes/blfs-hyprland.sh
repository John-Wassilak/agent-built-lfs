#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. The compositor itself -- needs everything above plus lcms2, muparser (BLFS, already built), glib2 (already built), and the X11/XCB tier for XWayland integration. Uses Arch's exact source URL (the GitHub release's bundled 'source' tarball, not a plain git-tag archive -- Hyprland's own release process vendors things the plain tag archive would not include) and its top-level Makefile wrapper around the real cmake build.
#
# DNS fix added 2026-08-31 (laptop): Hyprland's CMakeLists pins
# find_package(glaze 7...<8 QUIET) -- narrower than the system glaze this
# project builds (8.1.0, needed as-is by hyprtoolkit/hyprland-guiutils, so not
# downgraded). Not finding a compatible system glaze is a real, designed
# fallback in Hyprland's own CMakeLists, not a bug: it FetchContent-clones its
# own pinned glaze v7.2.0 instead, vendored just for this build. Needs live
# DNS the chroot doesn't have by default -- same fix as blfs-rust and friends
# (shared override), applied directly here since this recipe is hand-authored,
# not extractor-managed.
set -e

_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

# GCC 15.2's libstdc++ does not implement std::ranges::starts_with (a C++23
# range algorithm) even under -std=gnu++2c -- a real GCC/libstdc++ gap, not a
# packaging issue, confirmed by server's own build hitting the identical
# failure at the same one call site. Materialize the lowercased view into a
# real std::string and use the C++20 member function std::string::starts_with
# instead, which does work.
perl -0777 -pi -e 's/auto str_view = str \| std::views::transform\(\[\]\(unsigned char ch\) -> char \{\n        return sc<char>\(std::tolower\(ch\)\);\n    \}\);\n\n    return \[&\]\(auto&&\.\.\. prefixes\) -> bool \{\n        return \(\.\.\. \|\| std::ranges::starts_with\(str_view, prefixes\)\);\n    \}/std::string str_view;\n    str_view.reserve(str.size());\n    for (unsigned char ch : str)\n        str_view.push_back(sc<char>(std::tolower(ch)));\n\n    return [&](auto&&... prefixes) -> bool {\n        return (... || str_view.starts_with(prefixes));\n    }/' \
    src/helpers/MiscFunctions.cpp
grep -q 'str_view.starts_with' src/helpers/MiscFunctions.cpp || { echo "hyprland truthy() patch did not apply -- source changed upstream, needs a fresh look" >&2; exit 1; }

sed -i -e '/^release:/{n;s/-D/-DCMAKE_SKIP_RPATH=ON -D/}' Makefile
make release PREFIX=/usr
make install
rm -fv /usr/include/hyprland/src/version.h.in

echo "### version"
hyprctl version 2>&1 || Hyprland --version 2>&1 || true

