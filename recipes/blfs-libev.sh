#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Required by picom for its event loop.
# Standard autotools build.
#
# libev ships a `/usr/include/event.h` of its own -- a libevent COMPATIBILITY SHIM
# ("libevent compatibility header, only core events supported", libev's own words) that
# implements a subset of libevent 1.x. libevent installs a file at that exact path too,
# and whichever package is installed second wins. On `server` libev is seq 244 and
# libevent is seq 190, so libev always wins, and /usr/include/event.h stops being
# libevent's.
#
# That is not cosmetic. It broke the Firefox 153.2.0esr build on 2026-09-22, 81 minutes
# in: ipc/chromium/src/base/message_pump_libevent.cc does `#include "event.h"` and then
# static-asserts the EVENT__SIZEOF_* macros, so it failed with "Cannot find libevent type
# sizes", nine unknown type names, and `event_base_loopbreak` undeclared -- none of which
# libev's shim provides. It is invisible in a from-scratch build, because firefox (192)
# is built before libev (244) and sees libevent's real header; it only bites a later
# rebuild of anything that uses system libevent, which is exactly what a version sweep
# does.
#
# libev has no configure switch to suppress the shim (it is unconditional in
# include_HEADERS), so it is removed after install. Nothing here wants it: picom, libev's
# only consumer in this build, includes <ev.h>. Removing it restores libevent's own
# header, which is what every other consumer expects.
set -e

./configure --prefix=/usr --disable-static
make
make install

# See the header. Remove libev's libevent-compat shim so it cannot shadow libevent's own
# /usr/include/event.h. Guarded so this is safe if libev ever stops installing it.
if [ -e /usr/include/event.h ] && grep -q 'libevent compatibility header' /usr/include/event.h; then
    rm -v /usr/include/event.h
fi
