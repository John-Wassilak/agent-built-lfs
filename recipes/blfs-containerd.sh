#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for containerd (grepped all three).
# source: github.com/containerd/containerd, tag v2.4.0 (commit a7fe631d), GitHub
# archive tarball. Ships vendor/, so the build is offline.
#
# rationale: the container supervisor dockerd delegates to -- image pull and store,
# snapshots, and the runc shim that owns each running container. Part of the Docker
# stack requested 2026-09-23 (packages.py seq 256-262).
#
# Build choices:
# - BUILDTAGS=no_btrfs: the btrfs snapshotter is cgo against libbtrfsutil headers,
#   which no book installs here, and the root filesystem is ext4. overlayfs (kernel
#   OVERLAY_FS) is the snapshotter actually used.
# - VERSION/REVISION by hand: the Makefile derives both from `git describe` /
#   `git rev-parse`, and a tarball has no .git.
# - PREFIX=/usr, and upstream's containerd.service rewritten from /usr/local/bin to
#   match. Installed to /usr/lib/systemd/system but NOT enabled: docker.service
#   Wants= it, so starting Docker starts it.
# - containerd-stress (a load-testing tool) is built by `make` and removed after
#   install; nothing here uses it.
#
# No config.toml is written: containerd 2.x's built-in defaults are what dockerd
# expects, and `containerd config default` prints them if one is ever wanted.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export GOFLAGS=-mod=vendor

make BUILDTAGS=no_btrfs VERSION=v2.4.0 REVISION=a7fe631d96c08fb14cf8eff0afdc280e99c30a94
make PREFIX=/usr install
rm -f /usr/bin/containerd-stress

sed 's|/usr/local/bin/containerd|/usr/bin/containerd|' containerd.service \
    > /usr/lib/systemd/system/containerd.service
chmod 644 /usr/lib/systemd/system/containerd.service
systemctl daemon-reload

echo "### version"
/usr/bin/containerd --version
/usr/bin/ctr --version

rm -rf "$HOME/.cache/go-build"
