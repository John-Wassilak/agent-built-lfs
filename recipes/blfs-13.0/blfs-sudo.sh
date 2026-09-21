#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/sudo.html
# title  : Sudo-1.9.17p2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e06b076e1a11cbb271a10 Download size: 5.2 MB Estimated disk space required: 54 MB (add 10
#   ctx: MB for tests) Estimated build time: 0.2 SBU (with parallelism=4; add 0.1 SBU for tests)
#   ctx: Sudo Dependencies Optional Linux-PAM-1.7.2, MIT Kerberos V5-1.22.2, OpenLDAP-2.6.12, MTA
#   ctx: (that provides a sendmail command), AFS, libaudit, Opie, and Sssd Installation of Sudo
#   ctx: Install Sudo by running the following commands:
./configure --prefix=/usr         \
            --libexecdir=/usr/lib \
            --with-secure-path    \
            --with-env-editor     \
            --docdir=/usr/share/doc/sudo-1.9.17p2 \
            --with-passprompt="[sudo] password for %p: " &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: env LC_ALL=C make check |& tee make-check.log. Check the
#   ctx: results with grep failed make-check.log. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: who may run what). The installation installs a default configuration that has no
#   ctx: privileges installed for any user. A couple of common configuration changes are to set
#   ctx: the path for the super user and to allow members of the wheel group to execute all
#   ctx: commands after providing their own credentials. Use the following commands to create the
#   ctx: /etc/sudoers.d/00-sudo configuration file as the root user:
cat > /etc/sudoers.d/00-sudo << "EOF"
Defaults secure_path="/usr/sbin:/usr/bin"
%wheel ALL=(ALL) ALL
EOF
chmod 440 /etc/sudoers.d/00-sudo
usermod -aG wheel john

# --- block 3 --------------------------------------------------
#   ctx: evelopers highly recommend using the visudo program to edit the sudoers file. This will
#   ctx: provide basic sanity checking like syntax parsing and file permission to avoid some
#   ctx: possible mistakes that could lead to a vulnerable configuration. If PAM is installed on
#   ctx: the system, Sudo is built with PAM support. In that case, issue the following command as
#   ctx: the root user to create the PAM configuration file:
#   REVIEWED [drop]: PAM config for sudo. Linux-PAM is not part of this LFS 13.0 build (Shadow was built without it, confirmed when reviewing blfs-openssh) -- sudo was not built with --without-pam disabled explicitly, but configure auto-detects PAM's absence and skips it, so /etc/pam.d/sudo would configure a subsystem that isn't wired into anything.
# cat > /etc/pam.d/sudo << "EOF"
# # Begin /etc/pam.d/sudo
# 
# # include the default auth settings
# auth      include     system-auth
# 
# # include the default account settings
# account   include     system-account
# 
# # Set default environment variables for the service user
# session   required    pam_env.so
# 
# # include system session defaults
# session   include     system-session
# 
# # End /etc/pam.d/sudo
# EOF
# chmod 644 /etc/pam.d/sudo

