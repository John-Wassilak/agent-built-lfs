#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/xwayland.html
# title  : Xwayland-24.1.9
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: font-util) Recommended libepoxy-1.5.10, libtirpc-1.3.7, and Mesa-25.3.5 Optional
#   ctx: git-2.53.0 (to download packages needed for the tests), libei-1.5.0, libgcrypt-1.12.0,
#   ctx: Nettle-3.10.2, xmlto-0.0.29, Xorg Legacy Fonts (only bdftopcf, for building fonts
#   ctx: required for the tests), rendercheck (for tests), and weston (for tests) Installation of
#   ctx: Xwayland Install xwayland by running the following commands:
sed -i '/install_man/,$d' meson.build &&

mkdir build &&
cd    build &&

meson setup ..              \
      --prefix=$XORG_PREFIX \
      --buildtype=release   \
      -D xkb_output_dir=/var/lib/xkb &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: Building the test framework needs some work. First, weston brings in several
#   ctx: dependencies, but the number can be reduced by disabling unneeded features. The meson
#   ctx: command for a stripped down build of weston is shown in Upstream continuous integration
#   ctx: build. Running the tests involves downloading two other frameworks, in addition to the
#   ctx: mentioned optional dependencies:
#   REVIEWED [drop]: Same class of gap as blfs-vulkan-loader/blfs-libei: not auto-flagged by the testsuite classifier (a multi-step git-clone-and-build-a-test-framework block, not the usual 'make check' shape). Sets up piglit + xts (both git-cloned) and weston purely for the optional test suite -- none of it needed to build or install Xwayland itself. Confirmed failing 2026-08-31: the paired block 2 ('ninja test') failed needing /usr/bin/xkbcomp, not built at this point in the plan, and the whole piglit/weston/xts chain is exactly the kind of heavy optional test infra this project skips everywhere else.
# mkdir tools &&
# pushd tools &&
# 
# git clone https://gitlab.freedesktop.org/mesa/piglit.git --depth 1 &&
# cat > piglit/piglit.conf << EOF                                    &&
# [xts]
# path=$(pwd)/xts
# EOF
# 
# git clone https://gitlab.freedesktop.org/xorg/test/xts --depth 1   &&
# 
# export DISPLAY=:22           &&
# ../hw/vfb/Xvfb $DISPLAY &
# VFB_PID=$!                   &&
# cd xts                       &&
# CFLAGS=-fcommon ./autogen.sh &&
# make                         &&
# kill $VFB_PID                &&
# unset DISPLAY VFB_PID        &&
# popd

# --- block 2 --------------------------------------------------
#   ctx: Then the tests can be run with:
#   REVIEWED [drop]: The actual test run (XTEST_DIR=... PIGLIT_DIR=... ninja test) -- paired with block 1's now-dropped setup, see its reason.
# XTEST_DIR=$(pwd)/tools/xts PIGLIT_DIR=$(pwd)/tools/piglit ninja test

# --- block 3 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 4 --------------------------------------------------
#   ctx: If Xorg-Server-21.1.21 is not installed and you do not plan to install it later, you can
#   ctx: install Xvfb from this package. As the root user:
install -vm755 hw/vfb/Xvfb /usr/bin

