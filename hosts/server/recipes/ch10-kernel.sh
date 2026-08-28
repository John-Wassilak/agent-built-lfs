#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter10/kernel.html
# title  : 10.3. Linux-6.18.10
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: t configuring and building the kernel can be found at
#   ctx: https://anduin.linuxfromscratch.org/LFS/kernel-nutshell/. These references are a bit
#   ctx: dated, but still give a reasonable overview of the process. If all else fails, you can
#   ctx: ask for help on the lfs-support mailing list. Note that subscribing is required in order
#   ctx: for the list to avoid spam. Prepare for compilation by running the following command:
make mrproper

# --- block 1 --------------------------------------------------
#   ctx: This ensures that the kernel tree is absolutely clean. The kernel team recommends that
#   ctx: this command be issued prior to each kernel compilation. Do not rely on the source tree
#   ctx: being clean after un-tarring. There are several ways to configure the kernel options.
#   ctx: Usually, this is done through a menu-driven interface, for example:
bash /sources/kernel-config.sh

# --- block 2 --------------------------------------------------
#   ctx: See the README file for more information. If desired, skip kernel configuration by
#   ctx: copying the kernel config file, .config, from the host system (assuming it is available)
#   ctx: to the unpacked linux-6.18.10 directory. However, we do not recommend this option. It is
#   ctx: often better to explore all the configuration menus and create the kernel configuration
#   ctx: from scratch. Compile the kernel image and modules:
make

# --- block 3 --------------------------------------------------
#   ctx: es, module configuration in /etc/modprobe.d may be required. Information pertaining to
#   ctx: modules and kernel configuration is located in Section 9.3, “Overview of Device and
#   ctx: Module Handling” and in the kernel documentation in the linux-6.18.10/Documentation
#   ctx: directory. Also, modprobe.d(5) may be of interest. Unless module support has been
#   ctx: disabled in the kernel configuration, install the modules with:
make modules_install

# --- block 4 --------------------------------------------------
#   ctx: ied to the /boot directory. Caution If you've decided to use a separate /boot partition
#   ctx: for the LFS system (maybe sharing a /boot partition with the host distro), the files
#   ctx: copied below should go there. The easiest way to do that is to create the entry for
#   ctx: /boot in /etc/fstab first (read the previous section for details), then issue the
#   ctx: following command as the root user in the chroot environment:
#   TAGS: admon:caution   [DISABLED - review]
# mount /boot

# --- block 5 --------------------------------------------------
#   ctx: evice node is omitted in the command because mount can read it from /etc/fstab. The path
#   ctx: to the kernel image may vary depending on the platform being used. The filename below
#   ctx: can be changed to suit your taste, but the stem of the filename should be vmlinuz to be
#   ctx: compatible with the automatic setup of the boot process described in the next section.
#   ctx: The following command assumes an x86 architecture:
cp -v arch/x86/boot/bzImage /boot/vmlinuz-6.18.10-lfs-13.0-systemd

# --- block 6 --------------------------------------------------
#   ctx: System.map is a symbol file for the kernel. It maps the function entry points of every
#   ctx: function in the kernel API, as well as the addresses of the kernel data structures for
#   ctx: the running kernel. It is used as a resource when investigating kernel problems. Issue
#   ctx: the following command to install the map file:
cp -v System.map /boot/System.map-6.18.10

# --- block 7 --------------------------------------------------
#   ctx: The kernel configuration file .config produced by the make menuconfig step above
#   ctx: contains all the configuration selections for the kernel that was just compiled. It is a
#   ctx: good idea to keep this file for future reference:
cp -v .config /boot/config-6.18.10

# --- block 8 --------------------------------------------------
#   ctx: Install the documentation for the Linux kernel:
cp -r Documentation -T /usr/share/doc/linux-6.18.10

# --- block 9 --------------------------------------------------
#   ctx: insmod, uses /etc/modprobe.d/usb.conf for this purpose. This file needs to be created
#   ctx: so that if the USB drivers (ehci_hcd, ohci_hcd and uhci_hcd) have been built as modules,
#   ctx: they will be loaded in the correct order; ehci_hcd needs to be loaded prior to ohci_hcd
#   ctx: and uhci_hcd in order to avoid a warning being output at boot time. Create a new file
#   ctx: /etc/modprobe.d/usb.conf by running the following:
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

