#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/console.html
# title  : 9.6. Configuring the Linux Console
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rs from the program messages in the C.UTF-8 locale are LatArCyrHeb*.psfu.gz,
#   ctx: LatGrkCyr*.psfu.gz, Lat2-Terminus16.psfu.gz, and pancyrillic.f16.psfu.gz in
#   ctx: /usr/share/consolefonts (the other shipped console fonts lack glyphs of some characters
#   ctx: like the Unicode left/right quotation marks and the Unicode English dash). So set one of
#   ctx: them, for example Lat2-Terminus16.psfu.gz as the default console font:
echo FONT=Lat2-Terminus16 > /etc/vconsole.conf

# --- block 1 --------------------------------------------------
#   ctx: An example for a German keyboard and console is given below:
cat > /etc/vconsole.conf << "EOF"
KEYMAP=en
EOF

# --- block 2 --------------------------------------------------
#   ctx: You can change KEYMAP value at runtime by using the localectl utility:
#   REVIEWED [drop]: 'localectl set-keymap MAP' is a placeholder, and localectl needs a running systemd, unavailable in the chroot. Block 1 writes /etc/vconsole.conf directly.
# localectl set-keymap MAP

# --- block 3 --------------------------------------------------
#   ctx: Note Please note that the localectl command doesn't work in the chroot environment. It
#   ctx: can only be used after the LFS system is booted with systemd. You can also use localectl
#   ctx: utility with the corresponding parameters to change X11 keyboard layout, model, variant
#   ctx: and options:
#   REVIEWED [drop]: 'localectl set-x11-keymap LAYOUT [MODEL] ...' is a placeholder for X11, which LFS does not install, and needs a running systemd.
# localectl set-x11-keymap LAYOUT [MODEL] [VARIANT] [OPTIONS]

