#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for Docker Compose.
# source: github.com/docker/compose, tag v5.5.1 (commit 5f94fb0a), GitHub archive
# tarball.
#
# rationale: `docker compose`, the CLI plugin for multi-container definitions. Part
# of the Docker stack requested 2026-09-23 (packages.py seq 256-262).
#
# Unlike the rest of the Docker stack this tarball ships NO vendor/ directory, so
# `go build` fetches every module from the network -- the same situation as
# blfs-tailscale, handled the same way: pin resolv.conf to public resolvers for the
# step, restore the systemd-resolved stub on exit, and remove the module cache after
# (otherwise it is swept into the manifest as installed files; see PRACTICES.md).
#
# Upstream's Makefile target is `go build -trimpath -tags "$(GO_BUILDTAGS)" -ldflags
# "-w -X ${PKG}/internal.Version=..." ./cmd`. GO_BUILDTAGS defaults to `e2e` there,
# which only exposes test hooks, so it is left empty. Installed beside buildx in
# /usr/libexec/docker/cli-plugins.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export CGO_ENABLED=0

_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

PKG=github.com/docker/compose/v5
go build -trimpath -ldflags "-w -X $PKG/internal.Version=v5.5.1" \
    -o docker-compose ./cmd

install -v -D -m755 docker-compose /usr/libexec/docker/cli-plugins/docker-compose

echo "### version"
/usr/libexec/docker/cli-plugins/docker-compose version

rm -rf "$HOME/go" "$HOME/.cache/go-build"
