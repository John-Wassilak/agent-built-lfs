#!/bin/bash
# HAND-AUTHORED recipe -- host-specific fork of the shared recipes/blfs-cbindgen.sh,
# pinned to cbindgen-0.29.2 instead of the 13.1 book's documented 0.29.4.
#
# Forked 2026-09-09: Firefox-140.8.0esr's build (which invokes system cbindgen, "checking
# for cbindgen... /usr/bin/cbindgen") failed a real build with cbindgen-0.29.4: its
# webrender_ffi_generated.h came out with "error: use of undeclared identifier 'COUNT'"
# at the exact enum-sentinel pattern webrender's Rust FFI structs use -- a cbindgen code-
# generation regression/behavior change between 0.29.2 and 0.29.4, not a Firefox-source
# bug (nothing about Firefox 140.8.0esr changed here). laptop (still on 13.0 books,
# cbindgen-0.29.2) has already built this exact Firefox version successfully against
# this exact older cbindgen, confirming 0.29.2 is the proven-working pairing. cbindgen
# has no other consumer that cares about the exact version once built (it is a build-
# time-only CLI tool; mesa's own already-built artifacts do not link against it), so
# downgrading system-wide for this host has no effect on anything already built.
set -e

_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

cargo build --release

install -Dm755 target/release/cbindgen /usr/bin/
