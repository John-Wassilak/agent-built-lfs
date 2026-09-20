#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for opentofu.
# source: github.com/opentofu/opentofu, tag v1.12.6
# rationale: operator-requested infrastructure-as-code tool (Terraform
# fork). go.mod floor is go1.26.6, comfortably under this project's
# go1.27.0 -- but a real, separate incompatibility surfaced: grpc-go
# v1.79.3 (opentofu's pinned dependency) fails to compile under Go
# 1.27 with "undefined: http2.TrailerPrefix". Root cause, confirmed by
# reading the actual source, not guessed: golang.org/x/net/http2's
# server.go carries `//go:build !(go1.27 && !http2legacy)` -- Go 1.27
# absorbed HTTP/2 support into the standard library, and x/net's
# legacy standalone implementation now excludes itself under Go 1.27+
# unless the `http2legacy` build tag opts back in. grpc-go v1.79.3
# predates this transition and still references that now-excluded
# file unconditionally. `http2legacy` is the sanctioned escape hatch
# the x/net maintainers added for exactly this transition period, not
# a hack -- used directly (`go build`, not `make build`, since the
# Makefile's target has no way to pass an extra tag) rather than
# downgrading the Go toolchain just for this one package.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"

# DNS fix added 2026-09-09 (fresh chroot build): `go build` needs to fetch module
# dependencies from proxy.golang.org -- this chroot has no working /etc/resolv.conf
# by default, same class of issue as blfs-openbao/blfs-rust/blfs-rofi and others.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

go build -tags http2legacy -ldflags "-X main.version=v1.12.6" -o tofu ./cmd/tofu

install -v -m755 tofu /usr/bin/tofu

echo "### version"
/usr/bin/tofu version 2>&1 | head -1 || true
