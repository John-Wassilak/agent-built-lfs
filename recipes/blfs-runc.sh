#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for runc (grepped all three).
# source: github.com/opencontainers/runc, tag v1.5.1 (commit 8f2685a4), GitHub
# archive tarball. Ships vendor/, so the build is offline.
#
# rationale: the OCI runtime -- the thing that actually creates a container's
# namespaces and cgroup. containerd's runc shim execs it; dockerd never talks to it
# directly. Part of the Docker stack requested 2026-09-23 (packages.py seq 256-262).
#
# Build tags: upstream's default set is "seccomp urfave_cli_no_docs libpathrs".
# - seccomp: kept. Links libseccomp (BLFS, seq 256) via cgo; this is what applies
#   Docker's default syscall filter to every container.
# - libpathrs: dropped with RUNC_BUILDTAGS=-libpathrs. It is a separate Rust
#   library (cyphar/libpathrs >= 0.2.5) that no book carries and nothing else here
#   needs. runc's README lists it as optional; without it runc uses its in-tree Go
#   implementation of the same openat2/O_PATH path-safety checks.
#
# COMMIT is set by hand because the Makefile runs `git describe` and a tarball has no
# .git -- it would print a fatal error and embed an empty commit.
#
# Needs at runtime: BPF_SYSCALL + CGROUP_BPF (device control on cgroup v2), see
# bin/kernel-config-base.sh.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export GOFLAGS=-mod=vendor

make RUNC_BUILDTAGS=-libpathrs COMMIT=v1.5.1-0-g8f2685a4
make PREFIX=/usr install install-bash

echo "### version"
/usr/sbin/runc --version
/usr/sbin/runc features | grep -A3 '"seccomp"' | head -4

rm -rf "$HOME/.cache/go-build"
