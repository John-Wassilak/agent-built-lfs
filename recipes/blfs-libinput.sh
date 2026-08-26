#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Recommended by Hyprland's own aquamarine backend and by libxkbcommon. Arch's official libinput PKGBUILD as reference; no -D documentation flag needed -- it's a boolean option (not a feature like most other packages this session) already defaulting to false, and passing 'disabled' to a boolean option is a hard meson configure error (discovered via a real failure). tests=false added for the same reason as libevdev's, though here the meson.build itself guards the Check dependency with required:false so it wouldn't have hard-failed. debug-gui=false added after a real failure: that boolean option also defaults to true and hard-requires GTK3/GTK4 for the libinput debug-events tool's GUI, neither of which is built yet on this system (GTK3 is a later tier).
set -e

mkdir build && cd build
meson setup --prefix=/usr --buildtype=release -D tests=false -D debug-gui=false .. &&
ninja
ninja install

