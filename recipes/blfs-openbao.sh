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
