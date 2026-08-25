#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/openssh.html
# title  : OpenSSH-10.2p1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Sysstat-12.7.9 Installation of OpenSSH OpenSSH runs as two processes when connecting to
#   ctx: other computers. The first process is a privileged process and controls the issuance of
#   ctx: privileges as necessary. The second process communicates with the network. Additional
#   ctx: installation steps are necessary to set up the proper environment, which are performed
#   ctx: by issuing the following commands as the root user:
install -v -g sys -m700 -d /var/lib/sshd &&

groupadd -g 50 sshd        &&
useradd  -c 'sshd PrivSep' \
         -d /var/lib/sshd  \
         -g sshd           \
         -s /bin/false     \
         -u 50 sshd

# --- block 1 --------------------------------------------------
#   ctx: Install OpenSSH by running the following commands:
./configure --prefix=/usr                            \
            --sysconfdir=/etc/ssh                    \
            --with-privsep-path=/var/lib/sshd        \
            --with-default-path=/usr/bin             \
            --with-superuser-path=/usr/sbin:/usr/bin \
            --with-pid-dir=/run                      &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make -j1 tests. Now, as the root user:
make install &&
install -v -m755    contrib/ssh-copy-id /usr/bin     &&

install -v -m644    contrib/ssh-copy-id.1 \
                    /usr/share/man/man1              &&
install -v -m755 -d /usr/share/doc/openssh-10.2p1     &&
install -v -m644    INSTALL LICENCE OVERVIEW README* \
                    /usr/share/doc/openssh-10.2p1

# --- block 3 --------------------------------------------------
#   ctx: . Configuring OpenSSH Config Files ~/.ssh/*, /etc/ssh/ssh_config, and
#   ctx: /etc/ssh/sshd_config There are no required changes to any of these files. However, you
#   ctx: may wish to view the /etc/ssh/ files and make any changes appropriate for the security
#   ctx: of your system. One recommended change is that you disable root login via ssh. Execute
#   ctx: the following command as the root user to disable root login via ssh:
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# --- block 4 --------------------------------------------------
#   ctx: without typing in your password, first create ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub with
#   ctx: ssh-keygen and then copy ~/.ssh/id_rsa.pub to ~/.ssh/authorized_keys on the remote
#   ctx: computer that you want to log into. You'll need to change REMOTE_USERNAME and
#   ctx: REMOTE_HOSTNAME for the username and hostname of the remote computer and you'll also
#   ctx: need to enter your password for the ssh-copy-id command to succeed:
#   REVIEWED [drop]: Interactive 'ssh-keygen' followed by 'ssh-copy-id ... REMOTE_USERNAME@REMOTE_HOSTNAME' -- literal placeholders, and it would block on a prompt.
# ssh-keygen &&
# ssh-copy-id -i ~/.ssh/id_ed25519.pub REMOTE_USERNAME@REMOTE_HOSTNAME

# --- block 5 --------------------------------------------------
#   ctx: Once you've got passwordless logins working it's actually more secure than logging in
#   ctx: with a password (as the private key is much longer than most people's passwords). If you
#   ctx: would like to now disable password logins, as the root user:
#   REVIEWED [drop]: Appends 'PasswordAuthentication no' and 'KbdInteractiveAuthentication no', i.e. key-only auth. No authorized_keys exists on this system, so applying it together with the block above would leave no way to log in at all.
# echo "PasswordAuthentication no" >> /etc/ssh/sshd_config &&
# echo "KbdInteractiveAuthentication no" >> /etc/ssh/sshd_config

# --- block 6 --------------------------------------------------
#   ctx: If you added Linux-PAM support and you want ssh to use it then you will need to add a
#   ctx: configuration file for sshd and enable use of LinuxPAM. Note, ssh only uses PAM to check
#   ctx: passwords, if you've disabled password logins these commands are not needed. If you want
#   ctx: to use PAM, issue the following commands as the root user:
#   REVIEWED [drop]: Builds /etc/pam.d/sshd from /etc/pam.d/login. Linux-PAM is not part of LFS 13.0 and Shadow was built without it, so /etc/pam.d/login does not exist and the sed would fail.
# sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd &&
# chmod 644 /etc/pam.d/sshd &&
# echo "UsePAM yes" >> /etc/ssh/sshd_config

# --- block 7 --------------------------------------------------
#   ctx: Additional configuration information can be found in the man pages for sshd, ssh and
#   ctx: ssh-agent. Systemd Unit To start the SSH server at system boot, install the sshd.service
#   ctx: unit included in the blfs-systemd-units-20251204 package. Note Changing the setting of
#   ctx: ListenAddress in /etc/sshd/sshd_config is unsupported with the BLFS sshd systemd unit.
#   REVIEWED [drop]: 'make install-sshd' is a target of the blfs-systemd-units package, not of openssh's own Makefile -- the book shows it under 'Systemd Unit' referring to blfs-systemd-units-20251204. Running it in the openssh tree fails. Handled instead by the blfs-sshd-unit step.
# make install-sshd

