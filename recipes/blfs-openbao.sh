#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for openbao.
# source: github.com/openbao/openbao, tag v2.6.2
# rationale: operator-requested secrets-management server (Vault fork).
# Builds clean under this project's go1.27.0 (go.mod floor go1.25.8).
# `make dev` (not `make bin`/`dev-ui`) deliberately -- the UI build
# pulls in npm/node via assetcheck/install-ui-dependencies, `make dev`
# never touches either, produces the same `bao` server/CLI binary with
# CGO_ENABLED=0 (the Makefile's own default).
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"

# DNS fix added 2026-09-09 (fresh chroot build): `go build` needs to fetch module
# dependencies from proxy.golang.org (go.sum entries not already vendored/cached) --
# this chroot has no working /etc/resolv.conf by default, same class of issue as
# blfs-rust/blfs-attrs/blfs-rofi and others.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

# git init added 2026-09-09 (fresh chroot build): `make dev` shells out to git for a
# build-version string (confirmed via a real failure: "fatal: not a git repository")
# -- the extracted tarball is a plain source tree, not a checkout. An empty repo with
# one commit is enough to satisfy whatever git command wants *some* output; the exact
# version string it embeds is cosmetic (`bao version` output), not functional.
git init -q
git -c user.email=build@localhost -c user.name=build add -A
git -c user.email=build@localhost -c user.name=build commit -q --no-gpg-sign -m "openbao-2.6.2 (unpacked tarball, not a real checkout)"

make dev

install -v -m755 bin/bao /usr/bin/bao

install -v -d /etc/openbao /var/lib/openbao/data
cat > /etc/openbao/config.hcl << "EOF"
storage "file" {
  path = "/var/lib/openbao/data"
}
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true
}
EOF

install -v -d /usr/lib/systemd/system
cat > /usr/lib/systemd/system/openbao.service << "EOF"
[Unit]
Description=OpenBao secrets management server
Documentation=https://openbao.org/docs/
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/bao server -config=/etc/openbao/config.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "### version"
/usr/bin/bao version 2>&1 | head -1 || true
