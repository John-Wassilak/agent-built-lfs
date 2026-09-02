#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/shadow.html
# title  : 8.29. Shadow-4.19.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rce the use of strong passwords, install and configure Linux-PAM first. Then install and
#   ctx: configure shadow with the PAM support. Finally install libpwquality and configure PAM to
#   ctx: use it. Disable the installation of the groups program and its man pages, as Coreutils
#   ctx: provides a better version. Also, prevent the installation of manual pages that were
#   ctx: already installed in Section 8.3, “Man-pages-6.17”:
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

# --- block 1 --------------------------------------------------
#   ctx: ary to change the obsolete /var/spool/mail location for user mailboxes that Shadow uses
#   ctx: by default to the /var/mail location used currently. And, remove /bin and /sbin from the
#   ctx: PATH, since they are simply symlinks to their counterparts in /usr. Warning Including
#   ctx: /bin and/or /sbin in the PATH variable may cause some BLFS packages fail to build, so
#   ctx: don't do that in the .bashrc file or anywhere else.
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

# --- block 2 --------------------------------------------------
#   ctx: Prepare Shadow for compilation:
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --disable-logind    \
            --with-group-name-max-length=32

# --- block 3 --------------------------------------------------
#   ctx: vailable yet in the incomplete LFS system. But as we've discussed in Section 7.6,
#   ctx: “Creating Essential Files and Symlinks”, the /run/utmp file format will be completely
#   ctx: broken after year 2038. The LFS editors will attempt to resolve the issue before that
#   ctx: year. --without-libbsd Do not use the readpassphrase function from libbsd which is not
#   ctx: in LFS. Use the internal copy instead. Compile the package:
make

# --- block 4 --------------------------------------------------
#   ctx: This package does not come with a test suite. Install the package:
make exec_prefix=/usr install
make -C man install-man

# --- block 5 --------------------------------------------------
#   ctx: tasks. For a full explanation of what password shadowing means, see the doc/HOWTO file
#   ctx: within the unpacked source tree. If you use Shadow support, keep in mind that programs
#   ctx: which need to verify passwords (display managers, FTP programs, pop3 daemons, etc.) must
#   ctx: be Shadow-compliant. That is, they must be able to work with shadowed passwords. To
#   ctx: enable shadowed passwords, run the following command:
pwconv

# --- block 6 --------------------------------------------------
#   ctx: To enable shadowed group passwords, run:
grpconv

# --- block 7 --------------------------------------------------
#   ctx: user will be a member of a unique group on the system. If this behavior is undesirable,
#   ctx: you'll need to pass either the -g or -N parameter to useradd, or else change the setting
#   ctx: of USERGROUPS_ENAB in /etc/login.defs. See useradd(8) for more information. Second, to
#   ctx: change the default parameters, the file /etc/default/useradd must be created and
#   ctx: tailored to suit your particular needs. Create it with:
mkdir -p /etc/default
useradd -D --gid 999

# --- block 8 --------------------------------------------------
#   ctx: een created correctly. That is why we created the group users with this group ID in
#   ctx: Section 7.6, “Creating Essential Files and Symlinks.” CREATE_MAIL_SPOOL=yes This
#   ctx: parameter causes useradd to create a mailbox file for each new user. useradd will assign
#   ctx: the group ownership of this file to the mail group with 0660 permissions. If you would
#   ctx: rather not create these files, issue the following command:
sed -i '/MAIL/s/yes/no/' /etc/default/useradd

# --- block 9 --------------------------------------------------
#   ctx: 8.29.3. Setting the Root Password Choose a password for user root and set it by running:
passwd -l root
echo "### root password locked -- no valid password, root reachable only via sudo"

