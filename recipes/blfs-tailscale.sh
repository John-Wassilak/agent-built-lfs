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

# Shields up on every node, added 2026-09-24 (operator request: "set tailscale to
# 'shields up'... it should be the same across server and laptop"). Shields-up makes
# tailscaled's own packet filter refuse every connection initiated *from* the tailnet
# to this node; connections this node opens outward still work. It matters here
# because tailscaled's netfilter chain (ts-input) accepts everything on tailscale0
# ahead of this project's iptables rules, so without it any tailnet peer the ACLs
# allow could reach every port this machine listens on with a wildcard bind.
#
# How, and why not the other two ways (checked in this tag's source):
#   - A one-off `tailscale set --shields-up` stores the pref in tailscaled.state. That
#     file does not exist until the node first runs, it is not part of any manifest,
#     and a later `tailscale set --shields-up=false` silently undoes it for good.
#   - tailscaled's `--config` file (ipn/conf.go, format "alpha0") has a ShieldsUp
#     field, but it locks *every* pref against the CLI unless "Locked": false, and each
#     load also resets AdvertiseServices and the relay-server prefs
#     (ConfigVAlpha.ToPrefs sets those masks unconditionally). Too much side effect
#     for one setting.
#   - This drop-in re-asserts the one pref on every start. `tailscale set` sends only
#     the flags actually passed (setFlagSet.Visit in cmd/tailscale/cli/set.go) and has
#     no login-state check, so it touches nothing else and also works on a node that
#     has not logged in yet. Type=notify in the upstream unit means ExecStartPost runs
#     once tailscaled is ready to take LocalAPI calls.
#
# The leading `-` keeps a failed `set` from failing the unit, which would stop
# tailscaled outright. A failure shows up in `journalctl -u tailscaled`, and
# `tailscale debug prefs | grep ShieldsUp` is the check.
install -v -d /usr/lib/systemd/system/tailscaled.service.d
cat > /usr/lib/systemd/system/tailscaled.service.d/shields-up.conf << "EOF"
# Installed by blfs-tailscale. Re-applies shields-up on every tailscaled start; see
# the recipe for why a drop-in and not a one-off `tailscale set` or a --config file.
[Service]
ExecStartPost=-/usr/bin/tailscale set --shields-up
EOF
chmod 644 /usr/lib/systemd/system/tailscaled.service.d/shields-up.conf

echo "### version"
/usr/bin/tailscale --version 2>&1 | head -1 || true

# A running daemon picks up the drop-in on its next start; a fresh build (chroot, or
# a native host that has never run tailscaled) has nothing to reload.
if systemctl is-active --quiet tailscaled 2>/dev/null; then
    systemctl daemon-reload
    /usr/bin/tailscale set --shields-up
    echo "### shields-up applied to the running tailscaled"
fi

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
