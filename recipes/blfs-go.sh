#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for Go. Rationale: Go is required
# to build cliphist (clipboard-history tool for the Hyprland desktop stack).
# source: go.dev/dl (official upstream releases, not a book tarball)
#
# Go's own build system requires an EXISTING Go compiler to build Go from
# source (true since Go 1.5) -- there is no bootstrapping from C. Per Go's
# own documented policy, building go1.N requires a go1.M compiler where M is
# (N-2) rounded down to even; go1.27.0 needs go1.24 or later in that series.
# This mirrors how Rust is handled in this build (blfs-rust.sh): a small
# trusted bootstrap binary from the upstream project, used only to build the
# real toolchain, then discarded.
#
# Two tarballs, both fetched directly from go.dev/dl (sha256-verified below,
# not from this project's book-sourced wget-list/md5sums):
#   go1.24.13.linux-amd64.tar.gz  -- official prebuilt binary, bootstrap only
#   go1.27.0.src.tar.gz           -- source, this is what actually gets kept
#
# Go's source build is "in place": whatever directory the source tarball is
# extracted into becomes GOROOT permanently (no separate install step moves
# files elsewhere, unlike Rust's x.py install). So the source tarball is
# extracted directly to its final home under /opt, matching this project's
# existing convention for large third-party toolchains (/opt/rustc-*).
set -e

WORK=/root/build-go
mkdir -p "$WORK"
cd "$WORK"

wget -q https://go.dev/dl/go1.24.13.linux-amd64.tar.gz -O go1.24.13.linux-amd64.tar.gz
wget -q https://go.dev/dl/go1.27.0.src.tar.gz          -O go1.27.0.src.tar.gz

echo "1fc94b57134d51669c72173ad5d49fd62afb0f1db9bf3f798fd98ee423f8d730  go1.24.13.linux-amd64.tar.gz" | sha256sum -c -
echo "7002403d7cc44529ef6d26f69a44818263395ead7c16c05a5808ae047ebeb0e5  go1.27.0.src.tar.gz"          | sha256sum -c -

tar xzf go1.24.13.linux-amd64.tar.gz
mv go go1.24.13-bootstrap

tar xzf go1.27.0.src.tar.gz
mv go /opt/go-1.27.0
ln -svfn go-1.27.0 /opt/go

cd /opt/go-1.27.0/src
export GOROOT_BOOTSTRAP="$WORK/go1.24.13-bootstrap"
./make.bash

cat > /etc/profile.d/go.sh << "EOF"
# Begin /etc/profile.d/go.sh

pathprepend /opt/go/bin PATH

# End /etc/profile.d/go.sh
EOF

/opt/go/bin/go version

# Bootstrap binary and both tarballs are build-only -- not part of the
# installed toolchain (which lives entirely under /opt/go-1.27.0). Remove
# once the build above succeeds; same cleanup pattern used throughout this
# project for /root/build* directories.
cd /
rm -rf "$WORK"
