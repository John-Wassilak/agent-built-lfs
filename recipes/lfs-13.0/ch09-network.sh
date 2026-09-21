#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/network.html
# title  : 9.2. General Network Configuration
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ame resolution can be handled by systemd-resolved in place of a static /etc/resolv.conf
#   ctx: file. Both services are enabled by default. Note If you will not use systemd-networkd
#   ctx: for network configuration (for example, when the system is not connected to network, or
#   ctx: you want to use another utility like NetworkManager for network configuration), disable
#   ctx: a service to prevent an error message during boot:
#   REVIEWED [drop]: Only for systems with no network or managed by NetworkManager. We want normal systemd-networkd behaviour.
# systemctl disable systemd-networkd-wait-online

# --- block 1 --------------------------------------------------
#   ctx: oot environment. For most systems, there is only one network interface for each type of
#   ctx: connection. For example, the classic interface name for a wired connection is eth0. A
#   ctx: wireless connection will usually have the name wifi0 or wlan0. If you prefer to use the
#   ctx: classic or customized network interface names, there are three alternative ways to do
#   ctx: that: Mask udev's .link file for the default policy:
#   REVIEWED [drop]: Disables systemd predictable interface naming. We keep the default, which is more robust when the tree moves to unknown hardware.
# ln -s /dev/null /etc/systemd/network/99-default.link

# --- block 2 --------------------------------------------------
#   ctx: Create a manual naming scheme, for example by naming the interfaces something like
#   ctx: internet0, dmz0, or lan0. To do that, create .link files in /etc/systemd/network/ that
#   ctx: select an explicit name or a better naming scheme for your network interfaces. For
#   ctx: example:
#   REVIEWED [drop]: Example renaming a NIC by hard-coded MAC 12:34:45:78:90:AB. Hardware-specific illustration.
# cat > /etc/systemd/network/10-ether0.link << "EOF"
# [Match]
# # Change the MAC address as appropriate for your network device
# MACAddress=12:34:45:78:90:AB
# 
# [Link]
# Name=ether0
# EOF

# --- block 3 --------------------------------------------------
#   ctx: See systemd.link(5) for more information. In /boot/grub/grub.cfg, pass the option
#   ctx: net.ifnames=0 on the kernel command line. 9.2.1.2. Static IP Configuration The command
#   ctx: below creates a basic configuration file for a Static IP setup (using both
#   ctx: systemd-networkd and systemd-resolved):
#   REVIEWED [drop]: Static-IP example with a placeholder device name and the book's 192.168.0.2 sample addresses. We use DHCP.
# cat > /etc/systemd/network/10-eth-static.network << "EOF"
# [Match]
# Name=<network-device-name>
# 
# [Network]
# Address=192.168.0.2/24
# Gateway=192.168.0.1
# DNS=192.168.0.1
# Domains=<Your Domain Name>
# EOF

# --- block 4 --------------------------------------------------
#   ctx: Multiple DNS entries can be added if you have more than one DNS server. Do not include
#   ctx: DNS or Domains entries if you intend to use a static /etc/resolv.conf file. 9.2.1.3.
#   ctx: DHCP Configuration The command below creates a basic configuration file for an IPv4 DHCP
#   ctx: setup:
cat > /etc/systemd/network/10-dhcp.network << "EOF"
[Match]
Name=en* eth*

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true
EOF

# --- block 5 --------------------------------------------------
#   ctx: thods incompatible with systemd-resolved to configure your network interfaces (ex: ppp,
#   ctx: etc.), or if using any type of local resolver (ex: bind, dnsmasq, unbound, etc.), or any
#   ctx: other software that generates an /etc/resolv.conf (ex: a resolvconf program other than
#   ctx: the one provided by systemd), the systemd-resolved service should not be used. To
#   ctx: disable systemd-resolved, issue the following command:
#   REVIEWED [drop]: Only when another resolvconf provider generates /etc/resolv.conf. We use systemd-resolved.
# systemctl disable systemd-resolved

# --- block 6 --------------------------------------------------
#   ctx: onnection), create the /etc/resolv.conf file following the static configuration below
#   ctx: for the chroot environment so the name resolution will work in the chroot environment.
#   ctx: When you exit the chroot environment, remove it so systemd-resolved will create the
#   ctx: symlink on boot. 9.2.2.2. Static resolv.conf Configuration If a static /etc/resolv.conf
#   ctx: is desired, create it by running the following command:
ln -sfv /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# --- block 7 --------------------------------------------------
#   ctx: le Public DNS service using the IP addresses below as nameservers. Note The Google
#   ctx: Public IPv4 DNS addresses are 8.8.8.8 and 8.8.4.4 for IPv4, and 2001:4860:4860::8888 and
#   ctx: 2001:4860:4860::8844 for IPv6. 9.2.3. Configuring the system hostname During the boot
#   ctx: process, the file /etc/hostname is used for establishing the system's hostname. Create
#   ctx: the /etc/hostname file and enter a hostname by running:
echo "lfs" > /etc/hostname

# --- block 8 --------------------------------------------------
#   ctx: ostname) and the domain name with a “.” character. And, you need to contact the domain
#   ctx: provider to resolve the FQDN to your public IP address. Even if the computer is not
#   ctx: visible to the Internet, a FQDN is still needed for certain programs, such as MTAs, to
#   ctx: operate properly. A special FQDN, localhost.localdomain, can be used for this purpose.
#   ctx: Create the /etc/hosts file using the following command:
cat > /etc/hosts << "EOF"
127.0.0.1  localhost.localdomain localhost
127.0.1.1  lfs.localdomain lfs
::1        localhost ip6-localhost ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters
EOF

