#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for Go. Rationale: Go is required
# to build tailscale, openbao, and opentofu (all Go programs). Originally
# built 2026-08-26 for cliphist (Hyprland's clipboard-history tool); removed
# 2026-08-27 along with the rest of the Hyprland/Wayland chain when cliphist
# was its only consumer in this project; rebuilt the same night once it
# turned out to be needed again for an unrelated set of packages.
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

# Real bug found 2026-08-27, same class as Firefox's PATH gap: Go's own
# build (make.bash) needs $HOME (or $XDG_CACHE_HOME/$GOCACHE explicitly)
# to place its build cache, and a headless systemd-run invocation has
# neither set ("build cache is required, but could not be located").
# Exported explicitly so this recipe is correct regardless of how/where
# it's invoked, not just from an interactive login shell that happens to
# already have $HOME.
export HOME="${HOME:-/root}"

# DNS fix added 2026-09-01 (laptop): server never needed this because by
# the time it built Go, it was already a live native system with its own
# working systemd-resolved. laptop is still chroot-only at this point, and
# the two wget calls below need live DNS to reach go.dev -- same fix as
# every other live-fetch recipe in this build (rust, cargo-c, cbindgen,
# librsvg, hyprland). Harmless on a host where DNS already works.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

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
