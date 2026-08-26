#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Undocumented hard dependency of Hyprland itself -- discovered via a real CMake configure failure ('None of the required lua55;lua5.5;lua-55;lua-5.5;lua>=5.5;lua<5.6 found'). Distinct from lua5.4 (libinput's dependency, built earlier) -- Lua's own major versions are not ABI/API compatible, both coexist on this system under different pkg-config names. Arch's official 'lua' PKGBUILD (now tracking 5.5.x, not 5.4) as reference: same liblua.so.patch/paths.patch/lua.pc pattern as lua5.4, re-fetched liblua.so.patch fresh since its context lines differ per-version (paths.patch and lua.pc are byte-identical to lua5.4's, confirmed by matching checksums). TO_BIN left at its default (unlike the rest of this recipe's deliberate deviations): this project's lua5.4 recipe already installs generic /usr/bin/lua directly (a deviation from Arch's versioned-binary approach made before lua5.5 was known to be needed), so installing lua5.5's binaries too overwrites lua5.4's /usr/bin/lua and /usr/bin/luac -- accepted rather than fought: TO_BIN="" was tried first and fails outright (the Makefile's install rule has no guard for an empty file list, a real 'missing destination file operand' failure). Nothing on this system actually runs the Lua CLI, only pkg-config discovery matters for either version, so which binary ends up on PATH is immaterial. paths.patch (adds a /usr/ fallback to the interpreter's default LUA_PATH/LUA_CPATH search dirs, on top of /usr/local/) deliberately skipped here: it fails to apply cleanly against 5.5.1's luaconf.h (upstream reformatted macro/string spacing since the patch was written, a real failure discovered when this recipe was first run) and, since nothing runs the Lua interpreter itself on this system (library-only build), the runtime module search path it patches is moot anyway.
set -e

patch -Np1 -i ../liblua55.so.patch
sed "s/%VER%/5.5/g;s/%REL%/5.5.1/g" ../lua.pc > lua55.pc

make MYCFLAGS="-fPIC" MYLDFLAGS="" linux
make TO_LIB="liblua.so liblua.so.5.5 liblua.so.5.5.1" INSTALL_DATA='cp -d' INSTALL_TOP=/usr install
install -Dm644 lua55.pc /usr/lib/pkgconfig/lua55.pc
ln -sf lua55.pc /usr/lib/pkgconfig/lua5.5.pc
ln -sf lua55.pc /usr/lib/pkgconfig/lua-5.5.pc

