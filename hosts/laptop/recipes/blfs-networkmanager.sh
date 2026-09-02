#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/basicnet/networkmanager.html
# title  : NetworkManager-1.56.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of NetworkManager Fix the python scripts so that they use Python 3:
grep -rl '^#!.*python$' | xargs sed -i '1s/python/&3/'

# --- block 1 --------------------------------------------------
#   ctx: Install NetworkManager by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                    \
      --prefix=/usr               \
      --buildtype=release         \
      -D libaudit=no              \
      -D nmtui=false              \
      -D ovs=false                \
      -D ppp=false                \
      -D nbft=false               \
      -D selinux=false            \
      -D qt=false                 \
      -D session_tracking=systemd \
      -D nm_cloud_setup=false     \
      -D modem_manager=false      \
      -D introspection=false      &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: An already active graphical session with a bus address is necessary to run the tests. To
#   ctx: test the results, issue ninja test. A few tests may fail, depending on enabled kernel
#   ctx: options. Now, as the root user:
ninja install &&
rm -rf /usr/share/doc/NetworkManager-1.56.0 &&
mv -v /usr/share/doc/NetworkManager{,-1.56.0}

# --- block 3 --------------------------------------------------
#   ctx: If you have not passed the -D docs=true option to meson, you can install the
#   ctx: pregenerated manual pages with (as the root user):
for file in $(echo ../man/*.[1578]); do
    section=${file##*.} &&
    install -vdm 755 /usr/share/man/man$section
    install -vm 644 $file /usr/share/man/man$section/
done

# --- block 4 --------------------------------------------------
#   ctx: If you have not used -D docs=true, the pregenerated HTML documentation can also be
#   ctx: installed with (as the root user):
cp -Rv ../docs/{api,libnm} /usr/share/doc/NetworkManager-1.56.0

# --- block 5 --------------------------------------------------
#   ctx: switch will make NetworkManager lack some features (for example 802.1X). Configuring
#   ctx: NetworkManager Config Files /etc/NetworkManager/NetworkManager.conf Configuration
#   ctx: Information For NetworkManager to work, at least a minimal configuration file must be
#   ctx: present. Such a file is not installed with make install. Issue the following command as
#   ctx: the root user to create a minimal NetworkManager.conf file:
cat >> /etc/NetworkManager/NetworkManager.conf << "EOF"
[main]
plugins=keyfile
EOF

# --- block 6 --------------------------------------------------
#   ctx: This file should not be modified directly by users of the system. Instead, system
#   ctx: specific changes should be made using configuration files in the
#   ctx: /etc/NetworkManager/conf.d directory. To allow polkit to manage authorizations, add the
#   ctx: following configuration file:
cat > /etc/NetworkManager/conf.d/polkit.conf << "EOF"
[main]
auth-polkit=true
EOF

# --- block 7 --------------------------------------------------
#   ctx: To prevent NetworkManager from updating the /etc/resolv.conf file, add the following
#   ctx: configuration file:
cat > /etc/NetworkManager/conf.d/no-dns-update.conf << "EOF"
[main]
dns=none
EOF

# --- block 8 --------------------------------------------------
#   ctx: For additional configuration options, see man 5 NetworkManager.conf. To allow regular
#   ctx: users to configure network connections, you should add them to the netdev group, and
#   ctx: create a polkit rule that grants access. Run the following commands as the root user:
groupadd -fg 86 netdev &&
/usr/sbin/usermod -a -G netdev john

cat > /usr/share/polkit-1/rules.d/org.freedesktop.NetworkManager.rules << "EOF"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.isInGroup("netdev")) {
        return polkit.Result.YES;
    }
});
EOF

# --- block 9 --------------------------------------------------
#   ctx: Systemd Unit To start the NetworkManager daemon at boot, enable the previously installed
#   ctx: systemd unit by running the following command as the root user: Note If using Network
#   ctx: Manager to manage an interface, any previous configuration for that interface should be
#   ctx: removed, and the interface brought down prior to starting Network Manager.
systemctl enable NetworkManager

# --- block 10 --------------------------------------------------
#   ctx: Starting in version 1.11.2 of NetworkManager, a systemd unit named
#   ctx: NetworkManager-wait-online.service is enabled, which is used to prevent services that
#   ctx: require network connectivity from starting until NetworkManager establishes a
#   ctx: connection. To disable this behavior, run the following command as the root user:
systemctl disable NetworkManager-wait-online

