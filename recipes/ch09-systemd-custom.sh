#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/systemd-custom.html
# title  : 9.10. Systemd Usage and Configuration
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ttings indicated. This file is where the log level may be changed as well as some basic
#   ctx: logging settings. See the systemd-system.conf(5) manual page for details on each
#   ctx: configuration option. 9.10.2. Disabling Screen Clearing at Boot Time The normal behavior
#   ctx: for systemd is to clear the screen at the end of the boot sequence. If desired, this
#   ctx: behavior may be changed by running the following command:
mkdir -pv /etc/systemd/system/getty@tty1.service.d

cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF

# --- block 1 --------------------------------------------------
#   ctx: The boot messages can always be reviewed by using the journalctl -b command as the root
#   ctx: user. 9.10.3. Disabling tmpfs for /tmp By default, /tmp is created as a tmpfs. If this
#   ctx: is not desired, it can be overridden by executing the following command:
ln -sfv /dev/null /etc/systemd/system/tmp.mount

# --- block 2 --------------------------------------------------
#   ctx: es type v which in turn references type d (directory). This then creates the specified
#   ctx: directory if it is not present and adjusts the permissions and ownership as specified.
#   ctx: Contents of the directory will be subject to time based cleanup if the age argument is
#   ctx: specified. If the default parameters are not desired, then the file should be copied to
#   ctx: /etc/tmpfiles.d and edited as desired. For example:
mkdir -p /etc/tmpfiles.d
cp /usr/lib/tmpfiles.d/tmp.conf /etc/tmpfiles.d

# --- block 3 --------------------------------------------------
#   ctx: 9.10.5. Overriding Default Services Behavior The parameters of a unit can be overridden
#   ctx: by creating a directory and a configuration file in /etc/systemd/system. For example:
mkdir -pv /etc/systemd/system/foobar.service.d

cat > /etc/systemd/system/foobar.service.d/foobar.conf << EOF
[Service]
Restart=always
RestartSec=30
EOF

# --- block 4 --------------------------------------------------
#   ctx: s of frequently used commands: coredumpctl -r: lists all core dumps in reverse
#   ctx: chronological order. coredumpctl -1 info: shows the information from the last core dump.
#   ctx: coredumpctl -1 debug: loads the last core dump into GDB. Core dumps may use a lot of
#   ctx: disk space. The maximum disk space used by core dumps can be limited by creating a
#   ctx: configuration file in /etc/systemd/coredump.conf.d. For example:
mkdir -pv /etc/systemd/coredump.conf.d

cat > /etc/systemd/coredump.conf.d/maxuse.conf << EOF
[Coredump]
MaxUse=5G
EOF

