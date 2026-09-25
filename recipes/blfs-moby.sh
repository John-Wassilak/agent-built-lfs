#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for Docker (grepped all three).
# source: github.com/moby/moby, tag docker-v29.8.1 (commit 464cd50c), GitHub archive
# tarball. Ships vendor/, so the build is offline.
#
# rationale: dockerd (the Docker Engine daemon) and docker-proxy (userland port
# forwarder for published ports). Part of the Docker stack requested 2026-09-23
# (packages.py seq 256-262). The `docker` CLI is a separate repo, blfs-docker-cli.
#
# Built with upstream's own hack/make.sh `dynbinary` bundle rather than a bare
# `go build`: it assembles the build tags (adds `journald` when pkg-config finds
# libsystemd, which it does here) and the version ldflags. It refuses to run without
# .git unless DOCKER_GITCOMMIT is given, hence the explicit commit. dynbinary, not
# binary: the static build exists for distribution tarballs, and this box has the
# shared libc it would otherwise bundle.
#
# docker-init (tini, for `docker run --init`) is a separate C project, built by
# its own step (blfs-tini, seq 263) into /usr/libexec/docker/docker-init.
#
# Units: upstream contrib/init/systemd/docker.{service,socket}, unchanged, plus one
# drop-in ordering docker.service after iptables.service. BLFS's iptables script
# (/etc/systemd/scripts/iptables) begins with `iptables -F; iptables -X;
# iptables -t nat -F`, which deletes every DOCKER-* chain. At boot the drop-in makes
# the firewall load first. On a live system the same flush happens on any
# `systemctl restart iptables`, and Docker must be restarted after it
# (`systemctl restart docker` recreates the chains).
#
# The docker group: docker.socket is root:docker 0660, and membership is equivalent
# to root on this machine. john is added because the operator chose that on
# 2026-09-23; blfs-adduser-john (seq 177) is itself a shared recipe, so both hosts
# have this user.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export GOFLAGS=-mod=vendor

VERSION=29.8.1 DOCKER_GITCOMMIT=464cd50c3d9e92877d56940ea160de6fca7bea23 \
    bash hack/make.sh dynbinary

install -v -m755 bundles/dynbinary-daemon/dockerd      /usr/bin/dockerd
install -v -m755 bundles/dynbinary-daemon/docker-proxy /usr/bin/docker-proxy

install -v -m644 contrib/init/systemd/docker.service /usr/lib/systemd/system/docker.service
install -v -m644 contrib/init/systemd/docker.socket  /usr/lib/systemd/system/docker.socket
install -v -d /usr/lib/systemd/system/docker.service.d
cat > /usr/lib/systemd/system/docker.service.d/10-after-iptables.conf << 'EOF'
# agent-built-lfs: the BLFS iptables script flushes every chain, Docker's included.
# Load the firewall first; see recipes/blfs-moby.sh.
[Unit]
After=iptables.service
EOF

groupadd -f -r docker
if id john >/dev/null 2>&1; then usermod -aG docker john; fi

systemctl daemon-reload
systemctl enable docker.socket docker.service

echo "### version"
/usr/bin/dockerd --version
echo "### build tags"
go version -m /usr/bin/dockerd | grep -- '-tags='
echo "### group"
getent group docker

rm -rf "$HOME/.cache/go-build"
