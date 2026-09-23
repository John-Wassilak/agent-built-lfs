#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for the Docker CLI.
# source: github.com/docker/cli, tag v29.8.1 (commit 4a63305d), GitHub archive
# tarball. Ships vendor/, so the build is offline.
#
# rationale: the `docker` command. Talks to dockerd over /run/docker.sock. Part of
# the Docker stack requested 2026-09-23 (packages.py seq 256-262).
#
# The repo has vendor.mod rather than go.mod (it is deliberately not a published Go
# module). Upstream's scripts/with-go-mod.sh symlinks vendor.mod/.sum to go.mod/.sum
# for the duration of one command and removes them after; the build runs under it,
# the same way upstream's own Makefile runs every module-mode command.
# GO_LINKMODE=dynamic for the same reason as dockerd: the static link is for
# distribution tarballs.
#
# Man pages are not installed: generating them builds go-md2man and cobra's doc
# generator from source first. `docker <cmd> --help` carries the same text.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export GOFLAGS=-mod=vendor

VERSION=29.8.1 GITCOMMIT=4a63305 GO_LINKMODE=dynamic \
    bash scripts/with-go-mod.sh bash scripts/build/binary

install -v -m755 build/docker-linux-amd64 /usr/bin/docker
install -v -D -m644 contrib/completion/bash/docker \
    /usr/share/bash-completion/completions/docker

echo "### version"
/usr/bin/docker --version

rm -rf "$HOME/.cache/go-build"
