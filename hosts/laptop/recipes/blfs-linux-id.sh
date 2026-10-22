#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- laptop recipe: linux-id, a TPM-backed FIDO2 authenticator
# Copyright (c) 2026 John Wassilak
#
# HAND-AUTHORED recipe -- no BLFS book page for linux-id.
# source: github.com/matejsmycka/linux-id, tag v0.2.4 (2026-09-19, commit a3eabc5)
#
# rationale: operator request 2026-10-13, test passkey flows at roughly a YubiKey's bar
# without buying one. linux-id keeps each credential's private key in the TPM and
# presents itself to the browser as a USB HID security key through /dev/uhid, so
# Firefox talks to it over CTAP2 as it would to a real key. The kernel half (TCG_CRB,
# UHID) is the 2026-10-13 kernel, see BUILD-REPORT.md.
#
# Read before packaging (v0.2.4 source, not the README):
#   - The private key never leaves the TPM. tpm/tpm.go creates it with FixedTPM and
#     FixedParent under a primary derived from the owner hierarchy and a per-credential
#     random seed; the "key handle" is the TPM-wrapped private blob, the public area and
#     that seed. It is only usable on this TPM.
#   - ~/.config/linux-id/creds.json (ctap2/credstore.go, mode 0600) holds, per passkey,
#     that key handle plus the RP ID and the user name and display name in plaintext.
#     Copying the file elsewhere yields metadata, not a usable key.
#   - Key use needs no TPM authorization: owner hierarchy and child key both use an empty
#     password. User presence is a pinentry click enforced by linux-id itself, not by the
#     TPM. Any process that can open /dev/tpmrm0 and read creds.json can sign without the
#     click. A YubiKey enforces touch in hardware; this is the main gap against that bar.
#   - Attestation: "none" for CTAP2; CTAP1/U2F uses SoftU2F's published shared cert.
#
# Differences from upstream's install.sh, all host-specific, hence a host recipe:
#   - Device access by group, not uaccess. Upstream tags /dev/uhid and /dev/tpmrm0
#     `uaccess`, which only grants anything to a logind session. laptop runs Hyprland on
#     seatd, and `loginctl list-sessions` is empty (checked 2026-10-13), so uaccess is a
#     no-op here: it would also leave Firefox unable to open linux-id's hidraw node,
#     since 70-uaccess.rules is the only thing that opens security keys to the user.
#     The rule below gives all three to group `fido` instead. Membership is the
#     operator's call and is not made here.
#   - The user unit drops ConditionSecurity=tpm2: this systemd is built -TPM2, and
#     `systemd-analyze condition ConditionSecurity=tpm2` fails here with a working TPM.
#   - No prebuilt binary download, no migration of older installs, no service enable:
#     the unit is a user unit and enabling it is per-user.
#
# Security note on the group: /dev/uhid lets a member create any HID device, keyboards
# included, so `fido` is as strong as `input` (which can read every keystroke).
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"

# Module fetch from proxy.golang.org, verified against go.sum. Same resolv.conf
# handling as blfs-tailscale.sh / blfs-openbao.sh.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

go build -trimpath -o linux-id .
# The test suite runs against the in-memory backend and fakes; it needs no TPM.
go test ./...

install -v -m755 linux-id /usr/bin/linux-id

getent group fido >/dev/null || groupadd -r fido

install -v -d /usr/lib/udev/rules.d
cat > /usr/lib/udev/rules.d/70-linux-id.rules << "EOF"
# linux-id (TPM-backed FIDO2 authenticator): members of group fido may use the TPM
# resource manager, create HID devices, and open FIDO security keys. Runs after
# 60-fido-id.rules, which sets ID_SECURITY_TOKEN.
KERNEL=="uhid",   SUBSYSTEM=="misc",  GROUP="fido", MODE="0660"
KERNEL=="tpmrm0", SUBSYSTEM=="tpmrm", GROUP="fido", MODE="0660"
SUBSYSTEM=="hidraw", ENV{ID_SECURITY_TOKEN}=="1", GROUP="fido", MODE="0660"
EOF

install -v -d /usr/lib/modules-load.d
echo uhid > /usr/lib/modules-load.d/uhid.conf

# Upstream install.sh's unit, less ConditionSecurity=tpm2 (see above).
install -v -d /usr/lib/systemd/user
cat > /usr/lib/systemd/user/linux-id.service << "EOF"
[Unit]
Description=linux-id TPM-backed FIDO2 authenticator
Documentation=https://github.com/matejsmycka/linux-id
ConditionKernelModuleLoaded=uhid

[Service]
Type=simple
ExecStart=/usr/bin/linux-id

ProtectProc=noaccess
# pinentry may need /run/user/$UID/wayland-0 and the session bus
BindReadOnlyPaths=%t
BindReadOnlyPaths=%T/.X11-unix
# ~/.config, where creds.json lives
BindPaths=%E
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=tmpfs
PrivateTmp=true
PrivateNetwork=true
PrivatePIDs=true
PrivateUsers=true
ProtectHostname=true
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
RestrictAddressFamilies=AF_UNIX
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictRealtime=true
RestrictSUIDSGID=true
PrivateMounts=true

DeviceAllow=/dev/tpmrm0
DeviceAllow=/dev/uhid

[Install]
WantedBy=default.target
EOF

# Module cache and build cache, same cleanup as blfs-openbao.sh.
rm -rf "$HOME/go/pkg" "$HOME/.cache/go-build"

echo "### version"
ls -l /usr/bin/linux-id
