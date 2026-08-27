#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for lua-lgi.
# source: github.com/lgi-devs/lgi, tag 0.9.2.
# Rationale: awesome window manager's own build system hard-requires
# lgi to run (not truly optional despite AWESOME_IGNORE_LGI existing as
# a build-time escape hatch -- awesome's own doc/rc-generation Lua
# scripts require('lgi') unconditionally). See AWESOME-X11-PLAN.md.
#
# Real upstream bug found and patched: lgi 0.9.2 (latest tag) still
# calls the pre-5.4 two-argument lua_resume() signature
# (lgi/callable.c), unconditionally, for any LUA_VERSION_NUM >= 502 --
# Lua 5.4 added a required 4th parameter (int *nresults). Documented
# upstream as "experimental" 5.4 support (lgi-devs/lgi issues #247,
# #318) but never actually fixed in a release. Patched here with a
# version-gated >= 504 branch passing a discarded local int for the
# new parameter, rather than waiting on upstream.
#
# Built specifically against this project's lua5.4 (not the system
# default lua, which is lua5.5 -- see blfs-lua5.4.sh's header-fix
# note). No pkg-config-based Lua detection in this old Makefile; the
# LUA_CFLAGS/LIBFLAG overrides below point it at lua5.4 explicitly.
set -e

python3 - << 'PYEOF'
path = "lgi/callable.c"
with open(path) as f:
    content = f.read()
old = """#if LUA_VERSION_NUM >= 502
      res = lua_resume (L, NULL, npos);
#else
      res = lua_resume (L, npos);
#endif"""
new = """#if LUA_VERSION_NUM >= 504
      { int nresults_unused;
        res = lua_resume (L, NULL, npos, &nresults_unused); }
#elif LUA_VERSION_NUM >= 502
      res = lua_resume (L, NULL, npos);
#else
      res = lua_resume (L, npos);
#endif"""
assert old in content, "pattern not found -- lgi source changed?"
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
PYEOF

make LUA_VERSION=5.4 \
     LUA_CFLAGS="$(pkg-config --cflags lua5.4)" \
     LIBFLAG="-shared $(pkg-config --libs lua5.4)"
make -C lgi install PREFIX=/usr LUA_VERSION=5.4
