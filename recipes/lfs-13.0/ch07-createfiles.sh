#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter07/createfiles.html
# title  : 7.6. Creating Essential Files and Symlinks
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Historically, Linux maintained a list of the mounted file systems in the file /etc/mtab.
#   ctx: Modern kernels maintain this list internally and expose it to the user via the /proc
#   ctx: filesystem. To satisfy utilities that expect to find /etc/mtab, create the following
#   ctx: symbolic link:
ln -sv /proc/self/mounts /etc/mtab

# --- block 1 --------------------------------------------------
#   ctx: Create a basic /etc/hosts file to be referenced in some test suites, and in one of
#   ctx: Perl's configuration files as well:
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

# --- block 2 --------------------------------------------------
#   ctx: In order for user root to be able to login and for the name “root” to be recognized,
#   ctx: there must be relevant entries in the /etc/passwd and /etc/group files. Create the
#   ctx: /etc/passwd file by running the following command:
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

# --- block 3 --------------------------------------------------
#   ctx: The actual password for root will be set later. Create the /etc/group file by running
#   ctx: the following command:
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
clock:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# --- block 4 --------------------------------------------------
#   ctx: n the NFS server or the parent user namespace, but “do not exist” on the local machine
#   ctx: or in the separate namespace). We assign nobody and nogroup to avoid an unnamed ID. But
#   ctx: other distros may treat this ID differently, so any portable program should not depend
#   ctx: on this assignment. Some tests in Chapter 8 need a regular user. We add this user here
#   ctx: and delete this account at the end of that chapter.
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

# --- block 5 --------------------------------------------------
#   ctx: To remove the “I have no name!” prompt, start a new shell. Since the /etc/passwd and
#   ctx: /etc/group files have been created, user name and group name resolution will now work:
#   REVIEWED [drop]: 'exec /usr/bin/bash --login' is the book telling a human to restart their shell so id/whoami show the names just added to /etc/passwd. As a script line it REPLACES the shell, so everything after it silently never runs -- here that lost block 6, which creates /var/log/{btmp,lastlog,faillog,wtmp}. Confirmed missing from the built tree.
# exec /usr/bin/bash --login

# --- block 6 --------------------------------------------------
#   ctx: The login, agetty, and init programs (and others) use a number of log files to record
#   ctx: information such as who was logged into the system and when. However, these programs
#   ctx: will not write to the log files if they do not already exist. Initialize the log files
#   ctx: and give them proper permissions:
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

