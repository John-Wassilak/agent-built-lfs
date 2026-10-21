#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/postlfs/qemu.html
# title  : qemu-11.1.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: kage. Optional (Runtime) Systemd-261.2 Optional (for building the documentation)
#   ctx: sphinx_rtd_theme-3.1.0 Note This optional dependencies list is not comprehensive. See
#   ctx: the output of ./configure --help for a more complete list. Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/qemu KVM Prerequisites Before building qemu,
#   ctx: check to see if your processor supports Virtualization Technology (VT):
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html, 'KVM Prerequisites': a diagnostic grep the reader runs by eye to see whether the CPU has vmx/svm. Its exit status says nothing about the build, and on a CPU without VT it exits 1 and would abort a build that can still produce a working (TCG-only) qemu. Check it by hand before adding this step.
# grep -E '^flags.*(vmx|svm)' /proc/cpuinfo

# --- block 1 --------------------------------------------------
#   ctx: Installation of qemu The udev rule of LFS only allows the root user, the users owning a
#   ctx: local login session supported by the optional runtime dependency Systemd-261.2 or the
#   ctx: users in the kvm group to use the KVM device. As the root user, add any non-root users
#   ctx: that might use the KVM device either without Systemd-261.2 installed or remotely (via a
#   ctx: SSH connection) to the kvm group:
id john >/dev/null 2>&1 && usermod -a -G kvm john || echo "### john not created yet (blfs-adduser-john); add him to kvm by hand"

# --- block 2 --------------------------------------------------
#   ctx: Install qemu by running the following commands: Note Qemu is capable of running many
#   ctx: targets. The build process is also capable of building multiple targets at one time in a
#   ctx: comma delimited list assigned to --target-list. Run ./configure --help to get a complete
#   ctx: list of available targets.
if [ $(uname -m) = i686 ]; then
   QEMU_ARCH=i386-softmmu
else
   QEMU_ARCH=x86_64-softmmu
fi


mkdir -vp build &&
cd        build &&

../configure --prefix=/usr            \
             --sysconfdir=/etc        \
             --localstatedir=/var     \
             --target-list=$QEMU_ARCH \
             --audio-drv-list=alsa    \
             --disable-download       \
             --disable-pa             \
             --enable-slirp           \
             --docdir=/usr/share/doc/qemu-11.1.1 &&

unset QEMU_ARCH &&

make

# --- block 3 --------------------------------------------------
#   ctx: qemu uses ninja as a subprocess when building. To run the tests, issue: ninja test. The
#   ctx: test harness will download the external Python module pygdbmi to satisfy some tests.
#   ctx: Now, as the root user:
make install

# --- block 4 --------------------------------------------------
#   ctx: Change the permissions and ownership of a helper script, which is needed when using the
#   ctx: “bridge” network device (see below). Again as the root user, issue: Note You need to add
#   ctx: any users who might use the “bridge” network device into the kvm group even if
#   ctx: Systemd-261.2 is installed.
chgrp kvm  /usr/libexec/qemu-bridge-helper &&
chmod 4750 /usr/libexec/qemu-bridge-helper

# --- block 5 --------------------------------------------------
#   ctx: Note For convenience you may want to create a symbolic link to run the installed
#   ctx: program. For instance (as the root user):
ln -sv qemu-system-`uname -m` /usr/bin/qemu

# --- block 6 --------------------------------------------------
#   ctx: running under qemu the “guest.” We'll use these notations in the following text. Note
#   ctx: The following instructions assume the optional symbolic link, qemu, has been created.
#   ctx: Additionally, qemu should be run in a graphical environment. It is also possible to use
#   ctx: qemu “headless” or through SSH. See the documentation for the various possibilities.
#   ctx: Disk A virtual disk may be set up in the following way:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html, 'Using Qemu > Disk': example of creating a guest disk image (vdisk.img in the current directory, which here is the build tree). Usage, not installation.
# VDISK_SIZE=50G
# VDISK_FILENAME=vdisk.img
# qemu-img create -f qcow2 $VDISK_FILENAME $VDISK_SIZE

# --- block 7 --------------------------------------------------
#   ctx: k size and filename should be adjusted as desired. The actual size of the file will be
#   ctx: less than specified, but will expand as needed, so it is safe to put a high value.
#   ctx: Operating System To install an operating system, download an iso image from your
#   ctx: preferred Linux distribution. For the purposes of this example, we'll use
#   ctx: Fedora-16-x86_64-Live-LXDE.iso in the current directory. Run the following:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html, 'Using Qemu > Operating System': example that boots an installer ISO in a VM. Interactive and long-running; it would hang the build. Usage, not installation.
# qemu -enable-kvm                           \
#      -drive file=$VDISK_FILENAME           \
#      -cdrom Fedora-16-x86_64-Live-LXDE.iso \
#      -boot d                               \
#      -m 1G

# --- block 8 --------------------------------------------------
#   ctx: he -m option is the amount of memory to use for the virtual machine. The choice depends
#   ctx: on the load of the host. Modern distributions should be comfortable with 4GB. The
#   ctx: -enable-kvm option allows hardware acceleration. Without this switch, the emulation is
#   ctx: much slower. Defining the virtual hardware The virtual machine hardware is defined by
#   ctx: the qemu command line. An example command is given below:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html, 'Defining the virtual hardware': example VM command line, interactive (-serial mon:stdio). Usage, not installation.
# qemu -enable-kvm                  \
#      -smp 4                       \
#      -cpu host                    \
#      -m 1G                        \
#      -drive file=$VDISK_FILENAME  \
#      -cdrom grub-img.iso          \
#      -boot order=c,once=d,menu=on \
#      -net nic,netdev=net0         \
#      -netdev user,id=net0         \
#      -device ac97                 \
#      -vga std                     \
#      -serial mon:stdio            \
#      -name "fedora-16"

# --- block 9 --------------------------------------------------
#   ctx: rk devices can be used for this purpose. For example, there is the “socket” device,
#   ctx: which allows several guests to share a common virtual network. In the following section,
#   ctx: we describe in more details how to set up the “bridge” device, which allows the guests
#   ctx: to appear as if connected to the local network. All the commands below should be run as
#   ctx: the root user. Allow the host to forward IP packets:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html, 'Networking': enables IP forwarding for the bridge network device, part of the usage walkthrough and only needed for -netdev bridge. A host that wants bridged guests should make this decision deliberately, next to its firewall; it is not part of installing qemu.
# sysctl -w net.ipv4.ip_forward=1

# --- block 10 --------------------------------------------------
#   ctx: To make this permanent, add the command to /etc/sysctl.d/60-net-forward.conf:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html: persists block 9's ip_forward in /etc/sysctl.d/60-net-forward.conf (and appends, so a rebuild duplicates the line). Dropped with block 9.
# cat >> /etc/sysctl.d/60-net-forward.conf << EOF
# net.ipv4.ip_forward=1
# EOF

# --- block 11 --------------------------------------------------
#   ctx: Set up a required configuration file:
#   REVIEWED [drop]: BLFS 13.1 postlfs/qemu.html: /etc/qemu/bridge.conf allowing br0, the third step of the bridge setup. Names an interface (br0) that only exists if a host builds the bridge in the book's 'Advanced Network Setup'. Dropped with blocks 9-10.
# install -vdm 755 /etc/qemu &&
# echo allow br0 > /etc/qemu/bridge.conf

