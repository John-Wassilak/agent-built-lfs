#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: The openssh page points at blfs-systemd-units for sshd.service; 'make install-sshd' is that package's target, not openssh's.
set -e

# DESTDIR=/ installs to the right place AND makes the Makefile skip its
# `systemctl enable`, which cannot run in the chroot. Same trick, no patching.
make install-sshd DESTDIR=/

# Enable sshd.service by hand -- exactly what `systemctl enable` would do.
install -vdm755 /etc/systemd/system/multi-user.target.wants
ln -sfv /usr/lib/systemd/system/sshd.service \
        /etc/systemd/system/multi-user.target.wants/sshd.service

# BLFS's sshd.service has no host-key generation, and sshd refuses to start without
# host keys. Generate them on first start instead of baking them into the image, so
# the tree stays safe to copy: ssh-keygen -A only creates what is missing.
install -vdm755 /etc/systemd/system/sshd.service.d
cat > /etc/systemd/system/sshd.service.d/keygen.conf << "EOF"
[Service]
ExecStartPre=/usr/bin/ssh-keygen -A
EOF

sshd -t -f /etc/ssh/sshd_config 2>&1 | grep -v "no hostkeys available" || true
echo "### sshd.service enabled; host keys generated on first start"

