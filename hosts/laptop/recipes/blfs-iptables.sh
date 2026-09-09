#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/iptables.html
# title  : iptables-1.8.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Include any connection tracking protocols that will be used, as well as any protocols
#   ctx: that you wish to use for match support under the "Core Netfilter Configuration" section.
#   ctx: The above options are enough for running Creating a Personal Firewall With iptables
#   ctx: below. Installation of iptables Install iptables by running the following commands:
./configure --prefix=/usr      \
            --disable-nftables \
            --enable-libipq    &&
make

# --- block 1 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: replace these values with appropriate interface names for your system. Personal Firewall
#   ctx: A Personal Firewall is designed to let you access all the services offered on the
#   ctx: Internet while keeping your computer secure and your data private. Below is a slightly
#   ctx: modified version of Rusty Russell's recommendation from the Linux 2.4 Packet Filtering
#   ctx: HOWTO. It is still applicable to the Linux 6.x kernels.
install -v -dm755 /etc/systemd/scripts

cat > /etc/systemd/scripts/iptables << "EOF"
#!/bin/sh

# Begin /etc/systemd/scripts/iptables

# Insert connection-tracking modules
# (not needed if built into the kernel)
modprobe nf_conntrack
modprobe xt_LOG

# Enable broadcast echo Protection
echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts

# Disable Source Routed Packets
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
echo 0 > /proc/sys/net/ipv4/conf/default/accept_source_route

# Enable TCP SYN Cookie Protection
echo 1 > /proc/sys/net/ipv4/tcp_syncookies

# Disable ICMP Redirect Acceptance
# CHANGED from the book's Personal Firewall example, which writes `default` and never
# writes `all`. That leaves redirects accepted: the kernel's IN_DEV_RX_REDIRECTS
# (include/linux/inetdevice.h:126, checked in linux-6.18.49) is an OR of conf/all and
# the per-interface value whenever forwarding is off, and conf/all/accept_redirects
# defaults to 1, so `all` alone decides the answer no matter what the interfaces say.
# `default` is only the template copied into interfaces brought up later, so it cannot
# fix an interface that already exists. Both are written here: `all` closes it now,
# `default` keeps the book's line doing its intended job for interfaces created later.
# The book's other example on the same page (Masquerading Router) does write `all`, so
# this is an inconsistency inside the book, not a disagreement with it.
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/default/accept_redirects

# Do not send Redirect Messages
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects
echo 0 > /proc/sys/net/ipv4/conf/default/send_redirects

# Drop Spoofed Packets coming in on an interface, where responses
# would result in the reply going out a different interface.
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter

# Log packets with impossible addresses.
echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
echo 1 > /proc/sys/net/ipv4/conf/default/log_martians

# be verbose on dynamic ip-addresses  (not needed in case of static IP)
echo 2 > /proc/sys/net/ipv4/ip_dynaddr

# disable Explicit Congestion Notification
# too many routers are still ignorant
echo 0 > /proc/sys/net/ipv4/tcp_ecn

# Set a known state
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP

# These lines are here in case rules are already in place and the
# script is ever rerun on the fly. We want to remove all rules and
# pre-existing user defined chains before we implement new rules.
iptables -F
iptables -X
iptables -Z

iptables -t nat -F

# Allow local-only connections
iptables -A INPUT  -i lo -j ACCEPT

# Free output on any interface to any ip for any service
# (equal to -P ACCEPT)
iptables -A OUTPUT -j ACCEPT

# Permit answers on already established connections
# and permit new connections related to established ones
# (e.g. port mode ftp)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Not in the book's example: this box is administered entirely over SSH, and
# the book's own Personal Firewall script does not allow any inbound service,
# SSH included -- applying it unmodified would have locked out the only way
# in. Explicit allow for new inbound SSH connections; the ESTABLISHED,RELATED
# rule above already covers the rest of each session once it exists.
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT

# Not in the book's example either, and the reason it is here rather than in the shared
# file: it names this machine's VPN subnet and interface. nginx (blfs-nginx, seq 320)
# listens on 0.0.0.0:80, but the book's script opens no inbound port besides the SSH
# rule above -- /etc/nginx/nginx.conf's own header records that tcp/80 was deliberately
# left closed. Operator request 2026-09-09: reach it from the home router's WireGuard
# subnet. Scoped two ways: source 10.0.0.0/24 (the subnet in /etc/wireguard/wg0.conf's
# Address= and the peer's AllowedIPs=) and inbound interface wg+, which covers both wg0
# (split tunnel) and wg1 (full tunnel) -- same address, only one up at a time. The
# interface match is what makes the source match meaningful: a packet arriving on eth0
# or wlp4s0 claiming a 10.0.0.x source does not match this rule, so the LAN still has
# no path to tcp/80.
iptables -A INPUT -i wg+ -s 10.0.0.0/24 -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT

# Everything else is dropped by policy (no LOG rule -- the book's example logs
# every dropped packet, which on an internet-facing host is a constant stream
# of scan/noise traffic; not wanted here, dropped without a paper trail).

# ---------------------------------------------------------------------------------
# IPv6: blocked entirely. Operator request 2026-09-09.
#
# The book's script never touches ip6tables, which left all three v6 chains at policy
# ACCEPT with zero rules -- an unfiltered stack sitting behind a filtered one. It was
# bounded only by this machine having no global v6 address (`ip -6 addr show scope
# global` empty, link-local fe80 only), but sshd does listen on [::]:22, so on a hostile
# LAN it was reachable over link-local with nothing in front of it, and the day a router
# handed out a prefix it would have become globally reachable.
#
# Nothing here uses v6: the WireGuard endpoint is v4, tailscale runs v4 here (its
# ip6tables chains were absent entirely), and no service needs it. So this is a full
# block rather than a v4-style mirror -- no ICMPv6, no neighbour discovery, no router
# advertisements, which also means no v6 address will ever be configured.
ip6tables -P INPUT   DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT  DROP

ip6tables -F
ip6tables -X
ip6tables -Z

# The one exception, and it is not a compromise of the above: ::1. Software that resolves
# `localhost` gets ::1 first on this box, and DROP has no error to report, so a dropped
# loopback connection is a hang until the client times out and retries 127.0.0.1 -- not a
# clean failure. Blocking off-box v6 is the point; making local sockets time out is not.
# Drop these two lines if ::1 should die too.
ip6tables -A INPUT  -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# End /etc/systemd/scripts/iptables
EOF
chmod 700 /etc/systemd/scripts/iptables

# --- block 3 --------------------------------------------------
#   ctx: e connected to the Internet, here WAN1. To provide the maximum security for the firewall
#   ctx: itself, make sure that there are no unnecessary servers running on it such as X11. As a
#   ctx: general principle, the firewall itself should not access any untrusted service (think of
#   ctx: a remote server giving answers that makes a daemon on your system crash, or even worse,
#   ctx: that implements a worm via a buffer-overflow).
#   REVIEWED [drop]: The 'Masquerading Router' example -- two network interfaces (LAN1/WAN1), NAT/routing between them. This box has one NIC (enp6s0) and is a single server, not a router; the block references interface names that do not exist here.
# install -v -dm755 /etc/systemd/scripts
# 
# cat > /etc/systemd/scripts/iptables << "EOF"
# #!/bin/sh
# 
# # Begin /etc/systemd/scripts/iptables
# 
# echo
# echo "You're using the example configuration for a setup of a firewall"
# echo "from Beyond Linux From Scratch."
# echo "This example is far from being complete, it is only meant"
# echo "to be a reference."
# echo "Firewall security is a complex issue, that exceeds the scope"
# echo "of the configuration rules below."
# 
# echo "You can find additional information"
# echo "about firewalls in Chapter 4 of the BLFS book."
# echo "https://www.linuxfromscratch.org/blfs"
# echo
# 
# # Insert iptables modules (not needed if built into the kernel).
# 
# modprobe nf_conntrack
# modprobe nf_conntrack_ftp
# modprobe xt_conntrack
# modprobe xt_LOG
# modprobe xt_state
# 
# # Enable broadcast echo Protection
# echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
# 
# # Disable Source Routed Packets
# echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
# 
# # Enable TCP SYN Cookie Protection
# echo 1 > /proc/sys/net/ipv4/tcp_syncookies
# 
# # Disable ICMP Redirect Acceptance
# echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
# 
# # Don't send Redirect Messages
# echo 0 > /proc/sys/net/ipv4/conf/default/send_redirects
# 
# # Drop Spoofed Packets coming in on an interface where responses
# # would result in the reply going out a different interface.
# echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter
# 
# # Log packets with impossible addresses.
# echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
# 
# # Be verbose on dynamic ip-addresses  (not needed in case of static IP)
# echo 2 > /proc/sys/net/ipv4/ip_dynaddr
# 
# # Disable Explicit Congestion Notification
# # Too many routers are still ignorant
# echo 0 > /proc/sys/net/ipv4/tcp_ecn
# 
# # Set a known state
# iptables -P INPUT   DROP
# iptables -P FORWARD DROP
# iptables -P OUTPUT  DROP
# 
# # These lines are here in case rules are already in place and the
# # script is ever rerun on the fly. We want to remove all rules and
# # pre-existing user defined chains before we implement new rules.
# iptables -F
# iptables -X
# iptables -Z
# 
# iptables -t nat -F
# 
# # Allow local connections
# iptables -A INPUT  -i lo -j ACCEPT
# iptables -A OUTPUT -o lo -j ACCEPT
# 
# # Allow forwarding if the initiated on the intranet
# iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# iptables -A FORWARD ! -i WAN1 -m conntrack --ctstate NEW       -j ACCEPT
# 
# # Do masquerading
# # (not needed if intranet is not using private ip-addresses)
# iptables -t nat -A POSTROUTING -o WAN1 -j MASQUERADE
# 
# # Log everything for debugging
# # (last of all rules, but before policy rules)
# iptables -A INPUT   -j LOG --log-prefix "FIREWALL:INPUT "
# iptables -A FORWARD -j LOG --log-prefix "FIREWALL:FORWARD "
# iptables -A OUTPUT  -j LOG --log-prefix "FIREWALL:OUTPUT "
# 
# # Enable IP Forwarding
# echo 1 > /proc/sys/net/ipv4/ip_forward
# 
# # The following sections allow inbound packets for specific examples
# # Uncomment the example lines and adjust as necessary
# 
# # Allow ping on the external interface
# #iptables -A INPUT  -p icmp -m icmp --icmp-type echo-request -j ACCEPT
# #iptables -A OUTPUT -p icmp -m icmp --icmp-type echo-reply   -j ACCEPT
# 
# # Reject ident packets with TCP reset to avoid delays with FTP or IRC
# #iptables -A INPUT  -p tcp --dport 113 -j REJECT --reject-with tcp-reset
# 
# # Allow HTTP and HTTPS to 192.168.0.2
# #iptables -A PREROUTING -t nat -i WAN1 -p tcp --dport 80 -j DNAT --to 192.168.0.2
# #iptables -A PREROUTING -t nat -i WAN1 -p tcp --dport 443 -j DNAT --to 192.168.0.2
# #iptables -A FORWARD -p tcp -d 192.168.0.2 --dport 80 -j ACCEPT
# #iptables -A FORWARD -p tcp -d 192.168.0.2 --dport 443 -j ACCEPT
# 
# # End /etc/systemd/scripts/iptables
# EOF
# chmod 700 /etc/systemd/scripts/iptables

# --- block 4 --------------------------------------------------
#   ctx: e capabilities of the firewall code in Linux. Have a look at the man page of iptables.
#   ctx: There you will find much more information. The port numbers needed for this can be found
#   ctx: in /etc/services, in case you didn't find them by trial and error in your log file.
#   ctx: Systemd Unit To set up the iptables firewall at boot, install the iptables.service unit
#   ctx: included in the blfs-systemd-units-20251204 package.
#   REVIEWED [drop]: 'make install-iptables' is a target of the blfs-systemd-units package's Makefile, not iptables' own -- same situation as blfs-openssh block 7 for sshd.service. Handled by the blfs-iptables-unit step instead, run from the blfs-systemd-units source tree.
# make install-iptables

