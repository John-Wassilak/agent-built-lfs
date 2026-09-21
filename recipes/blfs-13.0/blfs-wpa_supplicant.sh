#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/wpa_supplicant.html
# title  : wpa_supplicant-2.11
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: or Wireless for details. Installation of WPA Supplicant First you will need to create an
#   ctx: initial configuration file for the build process. You can read wpa_supplicant/README and
#   ctx: wpa_supplicant/defconfig for the explanation of the following options as well as other
#   ctx: options that can be used. Create a build configuration file that should work for
#   ctx: standard WiFi setups by running the following command:
cat > wpa_supplicant/.config << "EOF"
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3
EOF

# --- block 1 --------------------------------------------------
#   ctx: If you wish to use WPA Supplicant with NetworkManager-1.56.0, add the following options
#   ctx: to the WPA Supplicant build configuration file by running the following command:
cat >> wpa_supplicant/.config << "EOF"
CONFIG_CTRL_IFACE_DBUS=y
CONFIG_CTRL_IFACE_DBUS_NEW=y
CONFIG_CTRL_IFACE_DBUS_INTRO=y
EOF

# --- block 2 --------------------------------------------------
#   ctx: Install WPA Supplicant by running the following commands:
cd wpa_supplicant &&
make BINDIR=/usr/sbin LIBDIR=/usr/lib

# --- block 3 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
install -v -m755 wpa_{cli,passphrase,supplicant} /usr/sbin/ &&
install -v -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/ &&
install -v -m644 doc/docbook/wpa_{cli,passphrase,supplicant}.8 /usr/share/man/man8/

# --- block 4 --------------------------------------------------
#   ctx: Install the systemd support files by running the following command as the root user:
install -v -m644 systemd/*.service /usr/lib/systemd/system/

# --- block 5 --------------------------------------------------
#   ctx: If you have built WPA Supplicant with D-Bus support, you will need to install D-Bus
#   ctx: configuration files. Install them by running the following commands as the root user:
install -v -m644 dbus/fi.w1.wpa_supplicant1.service \
                 /usr/share/dbus-1/system-services/ &&
install -v -d -m755 /etc/dbus-1/system.d &&
install -v -m644 dbus/dbus-wpa_supplicant.conf \
                 /etc/dbus-1/system.d/wpa_supplicant.conf

# --- block 6 --------------------------------------------------
#   ctx: ollowing this section simultaneously can cause subtle issues. Config File
#   ctx: /etc/wpa_supplicant/wpa_supplicant-*.conf Configuration Information To connect to an
#   ctx: access point that uses a password, you need to put the pre-shared key in
#   ctx: /etc/wpa_supplicant/wpa_supplicant-wifi0.conf. SSID is the string that the access
#   ctx: point/router transmits to identify itself. Run the following command as the root user:
#   REVIEWED [drop]: 'wpa_passphrase SSID | sed ...' -- SSID is a literal placeholder, and wpa_passphrase reads the real passphrase interactively from stdin if not given as a second argument, which would hang an unattended build. Not wanted anyway: NetworkManager (block 1's own CONFIG_CTRL_IFACE_DBUS additions exist specifically for this) manages wpa_supplicant instances itself via D-Bus, so a static per-SSID config file here is unnecessary and would go stale immediately.
# install -v -dm755 /etc/wpa_supplicant &&
# wpa_passphrase SSID | sed '/^\t#/d' > /etc/wpa_supplicant/wpa_supplicant-wifi0.conf

# --- block 7 --------------------------------------------------
#   ctx: installed: wpa_supplicant@.service wpa_supplicant-nl80211@.service
#   ctx: wpa_supplicant-wired@.service The only difference between 3 of them is what driver is
#   ctx: used for connecting (-D option). The first one uses the default driver, the second one
#   ctx: uses the nl80211 driver and the third one uses the wired driver. You can connect to the
#   ctx: wireless access point by running the following command as the root user:
#   REVIEWED [drop]: 'systemctl start wpa_supplicant@wlan0' -- a runtime usage example, not an install step, and would fail regardless (no running systemd, no wlan0 interface, in the chroot).
# systemctl start wpa_supplicant@wlan0

# --- block 8 --------------------------------------------------
#   ctx: To connect to the wireless access point at boot, simply enable the appropriate
#   ctx: wpa_supplicant service by running the following command as the root user:
#   REVIEWED [drop]: 'systemctl enable wpa_supplicant@wlan0' -- statically enabling a per-interface wpa_supplicant instance would fight NetworkManager for control of the wifi interface (NetworkManager spawns and manages its own wpa_supplicant processes via D-Bus, per block 1's CONFIG_CTRL_IFACE_DBUS build options). Not wanted on a NetworkManager-managed host.
# systemctl enable wpa_supplicant@wlan0

