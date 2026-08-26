#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: iptables.html's 'Systemd Unit' section: 'install the iptables.service unit included in the blfs-systemd-units package... make install-iptables'. Same package already used for sshd.service (blfs-sshd-unit) -- that target lives in blfs-systemd-units' own Makefile, not iptables', so it runs from this tree, separately. Unlike blfs-sshd-unit (built during the original chroot build, where systemctl could not run), this system is live now, so the Makefile's own 'systemctl enable' runs for real -- no DESTDIR trick needed.
set -e

make install-iptables

echo "### enabled:"
systemctl is-enabled iptables.service

