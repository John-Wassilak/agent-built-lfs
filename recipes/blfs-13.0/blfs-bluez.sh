#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/bluez.html
# title  : BlueZ-5.86
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of BlueZ First, fix a regression that prevents BlueZ from initializing
#   ctx: adapters in the latest release:
sed -i '4967,4968d' src/adapter.c

# --- block 1 --------------------------------------------------
#   ctx: Install BlueZ by running the following commands:
./configure --prefix=/usr         \
            --sysconfdir=/etc     \
            --localstatedir=/var  \
            --enable-library      &&
make

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: make check. Now, as the root user:
make install &&
ln -svf ../libexec/bluetooth/bluetoothd /usr/sbin

# --- block 3 --------------------------------------------------
#   ctx: Install the main configuration file as the root user:
install -v -dm555 /etc/bluetooth &&
install -v -m644 src/main.conf /etc/bluetooth/main.conf

# --- block 4 --------------------------------------------------
#   ctx: If desired, install the API documentation as the root user:
install -v -dm755 /usr/share/doc/bluez-5.86 &&
install -v -m644 doc/*.txt /usr/share/doc/bluez-5.86

# --- block 5 --------------------------------------------------
#   ctx: u don't have docutils-0.22.4 installed. ln -svf ../libexec/bluetooth/bluetoothd
#   ctx: /usr/sbin: This command makes access to the bluetooth daemon more convenient.
#   ctx: Configuring BlueZ Configuration Files /etc/bluetooth/main.conf is installed
#   ctx: automatically during the installation. Additionally, there are two supplementary
#   ctx: configuration files. You can optionally install the following files as the root user:
cat > /etc/bluetooth/rfcomm.conf << "EOF"
# Start rfcomm.conf
# Set up the RFCOMM configuration of the Bluetooth subsystem in the Linux kernel.
# Use one line per command
# See the rfcomm man page for options


# End of rfcomm.conf
EOF

# --- block 6 --------------------------------------------------
cat > /etc/bluetooth/uart.conf << "EOF"
# Start uart.conf
# Attach serial devices via UART HCI to BlueZ stack
# Use one line per device
# See the hciattach man page for options

# End of uart.conf
EOF

# --- block 7 --------------------------------------------------
#   ctx: Systemd Bluez Services To start the bluetoothd daemon at boot, enable the previously
#   ctx: installed systemd unit by running the following command as the root user:
systemctl enable bluetooth

# --- block 8 --------------------------------------------------
#   ctx: To start the obexd daemon for a user session (to support some Bluetooth programs using
#   ctx: it), enable the previously installed systemd unit for all users by running the following
#   ctx: command as the root user:
systemctl enable --global obex

