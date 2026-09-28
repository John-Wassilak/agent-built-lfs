#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/rsync.html
# title  : rsync-3.4.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ps://www.linuxfromscratch.org/patches/blfs/13.0/rsync-3.4.1-security_fix-1.patch rsync
#   ctx: Dependencies Recommended popt-1.19 Optional Doxygen-1.16.1 and xxhash Installation of
#   ctx: rsync For security reasons, running the rsync server as an unprivileged user and group
#   ctx: is encouraged. If you intend to run rsync as a daemon, create the rsyncd user and group
#   ctx: with the following commands issued by the root user:
groupadd -g 48 rsyncd &&
useradd -c "rsyncd Daemon" -m -d /home/rsync -g rsyncd \
    -s /bin/false -u 48 rsyncd

# --- block 1 --------------------------------------------------
#   ctx: First, fix a security vulnerability:
patch -Np1 -i ../rsync-3.4.1-security_fix-1.patch

# --- block 2 --------------------------------------------------
#   ctx: Install rsync by running the following commands:
./configure --prefix=/usr    \
            --disable-xxhash \
            --without-included-zlib &&
make

# --- block 3 --------------------------------------------------
#   ctx: If you have Doxygen-1.16.1 installed and wish to build HTML API documentation, issue:
#   REVIEWED [drop]: Optional Doxygen HTML API docs ('If you have Doxygen-1.16.1 installed and wish to build HTML API documentation'). Doxygen is not installed -- same doc-tool trap as popt, json-c, libassuan and the rest.
# doxygen

# --- block 4 --------------------------------------------------
#   ctx: To run the tests, fix one test and then run the test suite:
#   REVIEWED [drop]: Test suite ('To run the tests, fix one test and then run the test suite'). Not auto-flagged by the testsuite classifier because the block opens with the wildtest.c sed rather than 'make check'. Skipped under this project's BLFS test policy; server ran it once by hand on this same 13.0 page (commit eeb5029): 45 passed, 1 skipped (crtimes), 0 failed.
# sed -i '/typedef/d' wildtest.c &&
# make check

# --- block 5 --------------------------------------------------
#   ctx: Now, as the root user:
make install

# --- block 6 --------------------------------------------------
#   ctx: If you built the documentation, install it using the following commands as the root
#   ctx: user:
#   REVIEWED [drop]: Installs the Doxygen API docs from block 3, which is dropped.
# install -v -m755 -d          /usr/share/doc/rsync-3.4.1/api &&
# install -v -m644 dox/html/*  /usr/share/doc/rsync-3.4.1/api

# --- block 7 --------------------------------------------------
#   ctx: n with the system-installed zlib library. Configuring rsync Config Files
#   ctx: /etc/rsyncd.conf Configuration Information For client access to remote files, you may
#   ctx: need to install the OpenSSH-10.2p1 package to connect to the remote server. This is a
#   ctx: simple download-only configuration to set up running rsync as a server. See the
#   ctx: rsyncd.conf(5) man-page for additional options (i.e., user authentication).
cat > /etc/rsyncd.conf << "EOF"
# This is a basic rsync configuration file
# It exports a single module without user authentication.

motd file = /home/rsync/welcome.msg
use chroot = yes

[localhost]
    path = /home/rsync
    comment = Default rsync module
    read only = yes
    list = yes
    uid = rsyncd
    gid = rsyncd

EOF

# --- block 8 --------------------------------------------------
#   ctx: You can find additional configuration information and general documentation about rsync
#   ctx: at https://rsync.samba.org/documentation.html. Systemd Unit Note that you only need to
#   ctx: start the rsync server if you want to provide an rsync archive on your local machine.
#   ctx: You don't need this unit to run the rsync client. Install the rsyncd.service unit
#   ctx: included in the blfs-systemd-units-20251204 package.
make install-rsyncd

# --- block 9 --------------------------------------------------
#   ctx: ything else) and will start rsync daemon when something tries to connect to that port
#   ctx: and stop the daemon when the connection is terminated. This is called socket activation
#   ctx: and is analogous to using {,x}inetd on a SysVinit based system. By default, the first
#   ctx: method is used - rsync daemon is started at boot and stopped at shutdown. If the socket
#   ctx: method is desired, you need to run as the root user:
#   REVIEWED [drop]: Optional switch from the default service unit to socket activation ('If the socket method is desired'). The book's default is the service method, and the block presumes block 8's rsyncd unit is installed. Opt-in, true of any host.
# systemctl stop rsyncd &&
# systemctl disable rsyncd &&
# systemctl enable rsyncd.socket &&
# systemctl start rsyncd.socket

