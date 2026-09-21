#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/clock.html
# title  : 9.5. Configuring the System Clock
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rs for the timezone to the time shown by hwclock. For example, if you are currently in
#   ctx: the MST timezone, which is also known as GMT -0700, add seven hours to the local time.
#   ctx: systemd-timedated reads /etc/adjtime, and depending on the contents of the file, sets
#   ctx: the clock to either UTC or local time. Create the /etc/adjtime file with the following
#   ctx: contents if your hardware clock is set to local time:
#   REVIEWED [drop]: Creates /etc/adjtime with LOCAL, which is the book's opt-in for a hardware clock kept in local time. systemd assumes UTC when this file is absent, and UTC is the correct default for a Linux-only machine.
# cat > /etc/adjtime << "EOF"
# 0.0 0 0.0
# 0
# LOCAL
# EOF

# --- block 1 --------------------------------------------------
#   ctx: If /etc/adjtime isn't present at first boot, systemd-timedated will assume that hardware
#   ctx: clock is set to UTC and adjust the file according to that. You can also use the
#   ctx: timedatectl utility to tell systemd-timedated if your hardware clock is set to UTC or
#   ctx: local time:
#   REVIEWED [drop]: `timedatectl set-local-rtc 1` is the same local-time opt-in via a different route, and timedatectl needs a running systemd (PID 1), unavailable in the chroot.
# timedatectl set-local-rtc 1

# --- block 2 --------------------------------------------------
#   ctx: timedatectl can also be used to change system time and time zone. To change your current
#   ctx: system time, issue:
#   REVIEWED [drop]: Placeholder: `timedatectl set-time YYYY-MM-DD HH:MM:SS`. Also requires a running systemd.
# timedatectl set-time YYYY-MM-DD HH:MM:SS

# --- block 3 --------------------------------------------------
#   ctx: The hardware clock will also be updated accordingly. To change your current time zone,
#   ctx: issue:
#   REVIEWED [drop]: Placeholder: `timedatectl set-timezone TIMEZONE`. The timezone is already set by ch08-glibc via /etc/localtime -> America/Chicago.
# timedatectl set-timezone TIMEZONE

# --- block 4 --------------------------------------------------
#   ctx: You can get a list of available time zones by running:
#   REVIEWED [drop]: `timedatectl list-timezones` is informational, and requires a running systemd.
# timedatectl list-timezones

# --- block 5 --------------------------------------------------
#   ctx: ize the system time with remote NTP servers. The daemon is not intended as a replacement
#   ctx: for the well established NTP daemon, but as a client only implementation of the SNTP
#   ctx: protocol which can be used for less advanced tasks and on resource limited systems.
#   ctx: Starting with systemd version 216, the systemd-timesyncd daemon is enabled by default.
#   ctx: If you want to disable it, issue the following command:
#   REVIEWED [drop]: Optional: disables systemd-timesyncd for users running another NTP client. We keep timesyncd enabled.
# systemctl disable systemd-timesyncd

