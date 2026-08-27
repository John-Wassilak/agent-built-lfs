#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for awesome (not in BLFS at
# all; window managers documented there are only icewm/twm). Sourced
# from Arch's official packaging convention per this project's standing
# policy. source: github.com/awesomeWM/awesome, tag v4.3.
# See AWESOME-X11-PLAN.md for why awesome specifically (chosen over
# bspwm+sxhkd/i3 after abandoning Hyprland/Wayland for the NVIDIA
# 470.xx proprietary driver's VDPAU decode -- EGLStreams-only, no
# Hyprland/GBM path).
#
# Real problems hit building this 2019-era release against a current
# toolchain, each a genuine bug/gap, not guesswork:
#
# 1. CMakeLists.txt's `cmake_minimum_required` predates CMake 3.5,
#    which current CMake (4.x) refuses outright. Fixed with
#    -D CMAKE_POLICY_VERSION_MINIMUM=3.5 (CMake's own documented
#    workaround for exactly this).
#
# 2. Hard-requires `convert` (ImageMagick) for build-time icon
#    generation -- not listed as an awesome dependency anywhere in
#    BLFS, since ImageMagick isn't normally required for BLFS's own
#    (icewm/twm) window managers. Built ImageMagick first
#    (blfs-imagemagick.sh).
#
# 3. Needs Lua 5.4 specifically (Arch's own default; 5.4 confirmed
#    compatible via upstream discussion, 5.5 is untested/too new).
#    This system's *generic* /usr/include/lua.h and /usr/lib/liblua.so
#    point to Lua 5.5 (installed later than 5.4, see blfs-lua5.4.sh's
#    header-fix note) -- explicitly pointed CMake at the dedicated
#    lua5.4 paths via LUA_INCLUDE_DIR/LUA_LIBRARY.
#
# 4. lgi is NOT actually optional despite AWESOME_IGNORE_LGI existing
#    as a build-time bypass flag -- awesome's own doc/rc-generation Lua
#    scripts (which produce real runtime files, not just docs, even
#    with GENERATE_DOC=NO) unconditionally require('lgi'). Built
#    lua-lgi first (blfs-lua-lgi.sh, itself needed a real upstream
#    Lua-5.4-compatibility patch).
#
# 5. Those same doc/rc-generation build steps invoke the bare `lua`
#    command with no version hint at all (CMakeLists.txt: `COMMAND
#    lua ...`) -- resolves to the system's generic Lua 5.5, which can't
#    find our lua5.4-specific lgi install. Built a standalone Lua 5.4
#    CLI interpreter (source in $LUA54_SRC below) and prepended a
#    directory containing only a `lua` -> that binary symlink onto
#    PATH for the build, rather than overwriting the system's actual
#    default /usr/bin/lua (which lua5.5 legitimately owns until the
#    Hyprland/Wayland cleanup phase, see AWESOME-X11-PLAN.md).
#
# 6. CMakeLists.txt:457 has a genuine dead reference:
#    `add_dependencies(check check-qa check-examples)` where
#    check-examples is never defined anywhere in the file (an upstream
#    leftover from a removed feature). Not related to anything we
#    need (the `check` target runs tests, never invoked) -- patched
#    the line to drop the dead dependency rather than working around
#    it another way.
#
# 7. Real GCC-version issue, not project-specific: this code relies on
#    old tentative-definition ("common symbol") semantics for global
#    variables declared in headers without `extern`, which GCC 10+
#    stopped defaulting to. Without -fcommon: "multiple definition"
#    link errors across every .c file that includes the affected
#    headers. Added -D CMAKE_C_FLAGS=-fcommon -- the standard,
#    widely-used fix for building older C codebases against modern
#    GCC, not a correctness risk.
set -e

LUA54_SRC=/root/build-lua54-headers/lua-5.4.9   # built once for blfs-lua5.4.sh's header fix; reused here for its CLI binary
LUA54_BIN_DIR=/root/.lua54-build-path
mkdir -p "$LUA54_BIN_DIR"
if [ ! -x "$LUA54_SRC/src/lua" ]; then
    make -C "$LUA54_SRC" MYCFLAGS="-fPIC" MYLDFLAGS="" linux-readline
fi
ln -sf "$LUA54_SRC/src/lua" "$LUA54_BIN_DIR/lua"

sed -i 's/add_dependencies(check check-qa check-examples)/add_dependencies(check check-qa)/' CMakeLists.txt

mkdir build
cd build

cmake -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release -D GENERATE_DOC=NO \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -D LUA_INCLUDE_DIR=/usr/include/lua5.4 -D LUA_LIBRARY=/usr/lib/liblua5.4.so \
      -D OVERRIDE_VERSION=v4.3 \
      -D CMAKE_C_FLAGS=-fcommon \
      ..

export PATH="$LUA54_BIN_DIR:$PATH"
export LUA_PATH="/usr/share/lua/5.4/?.lua;/usr/share/lua/5.4/?/init.lua;;"
export LUA_CPATH="/usr/lib/lua/5.4/?.so;;"
export AWESOME_IGNORE_LGI=1

make -j"$(nproc)"
make install
