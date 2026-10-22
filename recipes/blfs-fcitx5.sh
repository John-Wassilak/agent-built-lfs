#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers fcitx5 (BLFS 13.0 carries no input
# method framework at all, neither IBus nor Fcitx).
# rationale: Vietnamese Telex/VNI input for a language course (operator request,
# 2026-10-21). The XKB `vn` layouts type the base letters but put tones on separate
# dead or combining keys; Telex needs an input method. Fcitx5 over IBus because it
# implements zwp_input_method_v2 directly, which is what wlroots-style compositors
# such as Hyprland offer, and because IBus would also need the Unicode UCD/CLDR data
# packages. The Vietnamese engine itself is blfs-fcitx5-bamboo.
# source: download.fcitx-im.org/fcitx5/fcitx5/fcitx5-5.1.23_dict.tar.zst (the _dict
# tarball carries the prebuilt en_dict, so BUILD_SPELL_DICT needs no network). Detached
# signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# fc5a451c664e1978e407567d7e3e0a8d8d2e1b7febe182aa4bb3a219090dd7d3.
#
# Options, each checked against 5.1.23's CMakeLists.txt:
#   - USE_SYSTEM_PLASMA_WAYLAND_PROTOCOLS=OFF: plasma-wayland-protocols is not
#     installed, and the tarball carries plasma-window-management.xml itself.
#   - ENABLE_TEST=OFF, ENABLE_TESTING_ADDONS left ON: fcitx5-bamboo's CMake requires
#     Fcitx5Module TestFrontend, which only the testing addons install.
#   - Event loop: auto, which picks sd-event since libsystemd is present.
#   - Yoga (classic UI layout) is the bundled copy, the default.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_INSTALL_LIBEXECDIR=libexec \
      -D USE_SYSTEM_PLASMA_WAYLAND_PROTOCOLS=OFF \
      -D ENABLE_TEST=OFF \
      -W no-dev
cmake --build build
cmake --install build
