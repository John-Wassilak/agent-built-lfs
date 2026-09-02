#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for tailscale.
# source: github.com/tailscale/tailscale, tag v1.102.3
# rationale: operator-requested VPN mesh tool. Pure Go, no cgo, builds
# clean under this project's go1.27.0 (tailscale's go.mod floor is
# go1.26.6). Only the two binaries a client node needs -- `tailscale`
# (CLI) and `tailscaled` (daemon) -- built directly via `go build`,
# skipping the repo's own build_dist.sh (that script exists to burn
# version/commit metadata into packaged releases; upstream's own docs
# say a plain go build is fine otherwise) and the dozens of unrelated
# tools under cmd/ (derper, k8s-operator, etc.).
#
# tailscaled needs a TUN device at runtime (CONFIG_TUN, not the
# in-kernel WIREGUARD module already built for wireguard-tools --
# tailscaled runs its own userspace WireGuard implementation over
# /dev/net/tun, a different kernel interface entirely) -- added to
# bin/kernel-config.sh and built into the kernel the same night.
set -e

# Same $HOME gap as blfs-go.sh: go build needs it (GOPATH/GOMODCACHE
# default from $HOME) and a headless systemd-run invocation has none.
export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export CGO_ENABLED=0

# DNS fix added 2026-09-01 (laptop): this tarball ships no vendor/ directory
# (confirmed by inspection), so `go build` fetches every module dependency
# live from the network -- server never needed this because it was already
# a live native system with working DNS by the time it built tailscale.
# Same fix as blfs-go.sh and every other live-fetch recipe in this build.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

go build -o tailscale   ./cmd/tailscale
go build -o tailscaled  ./cmd/tailscaled

install -v -m755 tailscale  /usr/bin/tailscale
install -v -m755 tailscaled /usr/sbin/tailscaled

install -v -d /etc/default
install -v -m644 cmd/tailscaled/tailscaled.defaults /etc/default/tailscaled

install -v -d /usr/lib/systemd/system
install -v -m644 cmd/tailscaled/tailscaled.service /usr/lib/systemd/system/tailscaled.service

echo "### version"
/usr/bin/tailscale --version 2>&1 | head -1 || true

# Cache cleanup added 2026-09-01 (laptop): this tarball ships no vendor/
# directory, so `go build` downloads every module dependency into
# $HOME/go/pkg/mod and $HOME/.cache/go-build (~1.7G combined, confirmed by
# du). Left in place, these get swept into the manifest by the driver's own
# -cnewer capture (they're freshly written during this step) as if they
# were files this package installed, and they eat real disk space for no
# reason once the two binaries above are already built and copied out --
# build-time cache, not an installed artifact, same category as blfs-go.sh's
# own /root/build-go cleanup.
rm -rf "$HOME/go" "$HOME/.cache/go-build"
