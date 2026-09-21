#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for lua-lgi.
# source: github.com/lgi-devs/lgi, tag 0.9.2.
# Rationale: awesome window manager's own build system hard-requires
# lgi to run (not truly optional despite AWESOME_IGNORE_LGI existing as
# a build-time escape hatch -- awesome's own doc/rc-generation Lua
# scripts require('lgi') unconditionally). See AWESOME-X11-PLAN.md.
#
# Real upstream bug found and patched (1): lgi 0.9.2 (latest tag) still
# calls the pre-5.4 two-argument lua_resume() signature
# (lgi/callable.c), unconditionally, for any LUA_VERSION_NUM >= 502 --
# Lua 5.4 added a required 4th parameter (int *nresults). Documented
# upstream as "experimental" 5.4 support (lgi-devs/lgi issues #247,
# #318) but never actually fixed in a release. Patched here with a
# version-gated >= 504 branch passing a discarded local int for the
# new parameter, rather than waiting on upstream.
#
# Real upstream bug found and patched (2): lgi/ffi.lua's load_enum()
# reads GEnumClass/GFlagsClass `values' with core.record.fromarray(),
# which requires that field to marshal as a raw C array pointer.
# Current GLib (2.88.3 here) annotates both fields as
# (array length=n_values) in GObject-2.0.gir, so gobject-introspection
# describes them as typed arrays, lgi marshals them into 1-based Lua
# tables of EnumValue/FlagsValue records, and fromarray() raises
#   bad argument #1 to 'fromarray' (lgi.record expected, got table)
# lgi/override/cairo.lua is the first caller -- it loads 26 cairo enums
# at require() time -- so the failure takes out the entire cairo
# binding and everything downstream of it. Concretely: awesome dies in
# gears.color with "attempt to call a nil value (field 'create_rgba')"
# and exits before drawing anything. Diagnosed 2026-09-21 on server's
# re-imaged 13.1 root, where glib is new enough to carry the
# annotation. Patched to accept either shape rather than pinning an
# older glib; lgi has had no release since 0.9.2 (2020) and the
# annotation is not going away.
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

python3 - << 'FFIEOF'
path = "lgi/ffi.lua"
with open(path) as f:
    content = f.read()
old = """   for i = 0, enum_class.n_values - 1 do
      local val = core.record.fromarray(enum_class.values, i)
      enum_component[core.upcase(val.value_nick):gsub('%-', '_')] = val.value
   end"""
new = """   local values = enum_class.values
   for i = 0, enum_class.n_values - 1 do
      -- GLib annotates GEnumClass/GFlagsClass `values' as
      -- (array length=n_values), so lgi marshals the field into a
      -- 1-based Lua table of records rather than the raw C array
      -- fromarray() wants. Accept either shape.
      local val
      if type(values) == 'table' then
\tval = values[i + 1]
      else
\tval = core.record.fromarray(values, i)
      end
      enum_component[core.upcase(val.value_nick):gsub('%-', '_')] = val.value
   end"""
assert old in content, "pattern not found -- lgi source changed?"
content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
FFIEOF

make LUA_VERSION=5.4 \
     LUA_CFLAGS="$(pkg-config --cflags lua5.4)" \
     LIBFLAG="-shared $(pkg-config --libs lua5.4)"
make -C lgi install PREFIX=/usr LUA_VERSION=5.4
