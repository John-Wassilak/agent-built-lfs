#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/cargo-c.html
# title  : cargo-c-0.10.20
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: g this package. The system certificate store may need to be set up with make-ca-1.16.1
#   ctx: before building this package. Installation of cargo-c First, download a file to ensure
#   ctx: that cargo uses the dependency versions specified by the upstream developers when this
#   ctx: cargo-c version (0.10.20) was released. Without this, the latest versions of the
#   ctx: dependencies would be used and they might cause breakages:
curl -fLO https://github.com/lu-zero/cargo-c/releases/download/v0.10.20/Cargo.lock

# --- block 1 --------------------------------------------------
#   ctx: cannot tell the package name and version from the file name Cargo.lock, so it's better
#   ctx: not to put the ambiguously-named file outside the cargo-c-0.10.20 directory. We use curl
#   ctx: here because the cURL-8.18.0 package should have been installed as a required dependency
#   ctx: of rustc-1.93.1. The md5sum of the file should be 021854be3ef40003288171a6c5c65181.
#   ctx: Install cargo-c by running the following commands:
export LIBSSH2_SYS_USE_PKG_CONFIG=1    &&
export LIBSQLITE3_SYS_USE_PKG_CONFIG=1 &&

cargo build --release

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: cargo test --release. Now, as the root user:
install -vm755 target/release/cargo-{capi,cbuild,cinstall,ctest} /usr/bin/

# --- block 3 --------------------------------------------------
#   ctx: Finally, unset the exported environment variables:
unset LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG

