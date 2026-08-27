#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS (which only has LuaJIT). libinput's device-quirk scripts want Lua 5.4 specifically via pkg-config as 'lua5.4' -- distinct from the LuaJIT build mpv wants later, not interchangeable. Adapted from Arch's official lua54 PKGBUILD, simplified: skips Arch's parallel C++-linked lua++ variant (nothing here needs it) and the lua5.4-style renamed binaries/libs (no other Lua version on this system to conflict with) -- kept is exactly what matters for discovery: a lua5.4.pc pkg-config file naming the real library, which is what libinput's meson.build actually probes for. INSTALL_TOP=/usr added after a real failure: the upstream Makefile defaults INSTALL_TOP to /usr/local, which put the actual lib/headers/binaries in /usr/local while lua.pc (hardcoded prefix=/usr) pointed pkg-config at /usr -- a mismatch that would have made libinput's dependency probe find the .pc file but not the library it describes.
#
# Fixed 2026-08-26 (found while building awesome, which needs Lua 5.4
# specifically -- 5.5 is untested/too new for it): upstream Lua's Makefile
# has NO multi-version header/library coexistence support at all -- every
# Lua release installs to the same generic /usr/include/lua.h and
# /usr/lib/liblua.so, unversioned. lua5.5 was built later (see
# blfs-lua5.5.sh) and silently overwrote lua5.4's headers at that shared
# path -- pkg-config lua5.4 --cflags still "worked" but returned 5.5's
# header content, and --libs's generic -llua resolved through the
# generic symlink to 5.5's .so, not 5.4's, despite the .pc file being
# named lua5.4.pc. Any package built against `pkg-config lua5.4` between
# lua5.5's install and this fix may have silently linked against 5.5
# instead -- not re-audited here, out of scope for this fix.
#
# Now installs headers to a dedicated /usr/include/lua5.4/ (never
# touched by lua5.5's install) and a dedicated liblua5.4.so link name,
# so lua5.4.pc is fully self-contained and version-correct regardless
# of what the generic unversioned names currently point to.
set -e

patch -Np1 -i ../liblua.so.patch
patch -Np1 -i ../paths.patch
sed "s/%VER%/5.4/g;s/%REL%/5.4.9/g" ../lua.pc > lua.pc

make MYCFLAGS="-fPIC" MYLDFLAGS="" linux-readline
make TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.9" INSTALL_DATA='cp -d' INSTALL_TOP=/usr install

install -d /usr/include/lua5.4
install -m644 src/lua.h src/luaconf.h src/lualib.h src/lauxlib.h src/lua.hpp /usr/include/lua5.4/
ln -sf liblua.so.5.4.9 /usr/lib/liblua5.4.so

sed -e "s|Cflags: -I\${includedir}|Cflags: -I\${includedir}/lua5.4|" \
    -e "s|Libs: -L\${libdir} -llua -lm|Libs: -L\${libdir} -llua5.4 -lm|" \
    lua.pc > lua5.4.pc
install -Dm644 lua5.4.pc /usr/lib/pkgconfig/lua5.4.pc
ln -sf lua5.4.pc /usr/lib/pkgconfig/lua-5.4.pc

