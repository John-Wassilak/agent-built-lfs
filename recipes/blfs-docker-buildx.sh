#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for buildx.
# source: github.com/docker/buildx, tag v0.37.1 (commit 0b265a9f), GitHub archive
# tarball. Ships vendor/, so the build is offline.
#
# rationale: `docker build`. Since Docker 23 the CLI hands `docker build` to the
# buildx plugin (BuildKit) and only falls back to the deprecated legacy builder, with
# a warning, when the plugin is missing. Part of the Docker stack requested
# 2026-09-23 (packages.py seq 256-262).
#
# Upstream builds release binaries inside its Dockerfile; this is that Dockerfile's
# `go build` line and ldflags run directly. Installed to /usr/libexec/docker/
# cli-plugins, one of the four system directories the CLI searches
# (cli-plugins/manager/manager_unix.go).
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export GOFLAGS=-mod=vendor
export CGO_ENABLED=0

PKG=github.com/docker/buildx
go build -trimpath -ldflags "-s -w -X $PKG/version.Version=v0.37.1 \
    -X $PKG/version.Revision=0b265a9f62db554fa9aba6dd19e1bd5704bc7d8a \
    -X $PKG/version.Package=$PKG" -o docker-buildx ./cmd/buildx

install -v -D -m755 docker-buildx /usr/libexec/docker/cli-plugins/docker-buildx

echo "### version"
/usr/libexec/docker/cli-plugins/docker-buildx version

rm -rf "$HOME/.cache/go-build"
