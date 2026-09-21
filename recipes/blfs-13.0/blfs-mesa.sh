#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/mesa.html
# title  : Mesa-25.3.5
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: vers are built. That will almost always work. However, it is not efficient. Depending on
#   ctx: your video hardware, you probably need only specific drivers. The first thing you need
#   ctx: to know is which type of video device you have. In some cases it is built into the CPU.
#   ctx: In others it is a separate PCI card. In either case you can tell what video hardware you
#   ctx: have by installing pciutils-3.14.0 and running:
#   REVIEWED [drop]: `lspci | grep VGA`, the book telling a reader to look up their own GPU before choosing drivers. A scripted build already knows: the answer is host.toml's [hardware].gpu, and the driver choice it feeds is block 2's host override. pciutils is also not necessarily installed this early.
# lspci | grep VGA

# --- block 1 --------------------------------------------------
#   ctx: ptic message Error: couldn't get an RGB, Double-buffered visual. Strictly speaking, it
#   ctx: can be compiled as a module. But the module will not be loaded automatically, so it's
#   ctx: more convenient to build it as a part of the kernel image. Installation of Mesa If you
#   ctx: have downloaded the xdemos patch (needed if testing the Xorg installation per BLFS
#   ctx: instructions), apply it by running the following command:
#   REVIEWED [drop]: Applies the optional xdemos patch ('If you have downloaded...'). Not fetched: it only adds demo programs for testing an Xorg install, which nothing here needs.
# patch -Np1 -i ../mesa-add_xdemos-4.patch

# --- block 2 --------------------------------------------------
#   ctx: Install Mesa by running the following commands:
mkdir build &&
cd    build &&

meson setup ..                 \
      --prefix=$XORG_PREFIX    \
      --buildtype=release      \
      -D platforms=x11,wayland \
      -D gallium-drivers=auto  \
      -D vulkan-drivers=auto   \
      -D valgrind=disabled     \
      -D video-codecs=all      \
      -D libunwind=disabled   &&

ninja

# --- block 3 --------------------------------------------------
#   ctx: Warning Please ask your lawyer or remove the -D video-codecs=all option if you will
#   ctx: distribute the compiled Mesa libraries and drivers to others. To test the results,
#   ctx: issue:
#   REVIEWED [drop]: Reconfigures with build-tests=true and runs the full suite, roughly doubling build time for verification not done for any other package in this build -- test suites are skipped throughout except the critical three in LFS Chapter 8.
# meson configure -D build-tests=true &&
# ninja test

# --- block 4 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 5 --------------------------------------------------
#   ctx: If desired, install the optional documentation by running the following commands as the
#   ctx: root user:
cp -rv ../docs -T /usr/share/doc/mesa-25.3.5

