#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/cbindgen.html
# title  : Cbindgen-0.29.4
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ace required: 255 MB (with tests) Estimated build time: 0.4 SBU (add 0.2 SBU for tests),
#   ctx: both on a 4-core machine cbindgen Dependencies Required rustc-1.97.1 Note An Internet
#   ctx: connection is needed for building this package. The system certificate store may need to
#   ctx: be set up with make-ca-1.16.1 before building this package. Installation of cbindgen
#   ctx: Install cbindgen by running the following commands:
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

cargo build --release

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: cargo test --release. Three tests in profile.rs are known to
#   ctx: fail because they expect some Rust unstable features disabled in the BLFS rustc-1.97.1
#   ctx: configuration. Now, as the root user:
install -Dm755 target/release/cbindgen /usr/bin/

