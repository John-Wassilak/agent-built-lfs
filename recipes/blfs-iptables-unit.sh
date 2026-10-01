#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: iptables.html's 'Systemd Unit' section: 'install the iptables.service unit included in the blfs-systemd-units package... make install-iptables'. Same package already used for sshd.service (blfs-sshd-unit) -- that target lives in blfs-systemd-units' own Makefile, not iptables', so it runs from this tree, separately. Unlike blfs-sshd-unit (built during the original chroot build, where systemctl could not run), this system is live now, so the Makefile's own 'systemctl enable' runs for real -- no DESTDIR trick needed.
#
# One change to the installed unit: After=network.target becomes
# Before=network-pre.target + Wants=network-pre.target, the ordering systemd.special(7)
# gives for firewall units. With After=network.target the firewall runs alongside
# anything else that touches xtables, tailscaled (After=network-pre.target) among them.
# laptop's 2026-10-01 boot hit both failures that follow from that: the BLFS script's
# iptables calls, which do not pass -w, lost the xtables lock eight times and the unit
# failed with half its rules in; had they won, the script's `iptables -F; iptables -X`
# would have deleted the ts-* chains tailscaled had just created. This is a sed on the
# installed file rather than a drop-in because a drop-in cannot remove an After=, and
# keeping it next to Before=network-pre.target is an ordering cycle (network.target is
# itself After=network-pre.target). docker.service is ordered after iptables.service
# by its own drop-in (blfs-moby.sh).
set -e

make install-iptables

sed -i 's/^After=network\.target$/Wants=network-pre.target\nBefore=network-pre.target/' \
    /usr/lib/systemd/system/iptables.service
grep -q '^Before=network-pre.target$' /usr/lib/systemd/system/iptables.service
systemctl daemon-reload

echo "### enabled:"
systemctl is-enabled iptables.service

