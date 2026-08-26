#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS (which only has LuaJIT). libinput's device-quirk scripts want Lua 5.4 specifically via pkg-config as 'lua5.4' -- distinct from the LuaJIT build mpv wants later, not interchangeable. Adapted from Arch's official lua54 PKGBUILD, simplified: skips Arch's parallel C++-linked lua++ variant (nothing here needs it) and the lua5.4-style renamed binaries/libs (no other Lua version on this system to conflict with) -- kept is exactly what matters for discovery: a lua5.4.pc pkg-config file naming the real library, which is what libinput's meson.build actually probes for. INSTALL_TOP=/usr added after a real failure: the upstream Makefile defaults INSTALL_TOP to /usr/local, which put the actual lib/headers/binaries in /usr/local while lua.pc (hardcoded prefix=/usr) pointed pkg-config at /usr -- a mismatch that would have made libinput's dependency probe find the .pc file but not the library it describes.
set -e

patch -Np1 -i ../liblua.so.patch
patch -Np1 -i ../paths.patch
sed "s/%VER%/5.4/g;s/%REL%/5.4.9/g" ../lua.pc > lua.pc

make MYCFLAGS="-fPIC" MYLDFLAGS="" linux-readline
make TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.9" INSTALL_DATA='cp -d' INSTALL_TOP=/usr install
install -Dm644 lua.pc /usr/lib/pkgconfig/lua5.4.pc
ln -sf lua5.4.pc /usr/lib/pkgconfig/lua-5.4.pc

