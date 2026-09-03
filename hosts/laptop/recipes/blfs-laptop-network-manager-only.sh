#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step. Host-specific: server
# deliberately runs plain systemd-networkd with no NetworkManager at all, so this is not
# a shared decision.
# rationale: USB boot test (2026-09-02, see BUILD-REPORT.md) found ethernet reported
# unreachable in nmcli. /etc/systemd/system/multi-user.target.wants showed both
# NetworkManager.service and systemd-networkd.service enabled at once -- LFS
# 13.0-systemd ships systemd-networkd enabled by default, and adding NetworkManager
# (seq 176, 2026-09-01) never disabled it, leaving two managers eligible to own the same
# links. NetworkManager is the one this host actually wants (it is what carries over the
# live host's real WiFi/connection state); disable the base image's networkd units so
# only NetworkManager manages interfaces.
set -e

systemctl disable systemd-networkd.service systemd-networkd.socket \
    systemd-network-generator.service

echo "### systemd-networkd units after disable:"
systemctl is-enabled systemd-networkd.service systemd-networkd.socket \
    systemd-network-generator.service || true
