#!/bin/bash
# CANDIDATE recipe extracted from the GLFS 13.1 book.
# source : book/glfs-13.1/core/libglvnd.html
# title  : libglvnd-1.7.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: xpose one or two EGL device extensions from EGL_EXT_device_base,
#   ctx: EGL_EXT_device_enumeration, and EGL_EXT_device_query. Some packages require that all
#   ctx: three extensions are present, although historically base proves that enumeration and
#   ctx: query is possible, since the latter two are newer extensions that separate the former
#   ctx: into two. Apply a patch to make libglvnd advertise all three if one is present:
patch -Np1 -i ../libglvnd-v1.7.0-ext_device-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Install libglvnd by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D hgl=false        \
            .. &&

ninja

# --- block 2 --------------------------------------------------
#   ctx: Now as the root user:
ninja install

# --- block 3 --------------------------------------------------
#   ctx: lib32 Installation of libglvnd Install lib32-libglvnd by running the following commands:
#   REVIEWED [drop]: Rebuilds libglvnd for 32-bit/multilib (--cross-file=lib32), a GLFS/MLFS prerequisite this project does not build for any host (no multilib toolchain -- GLFS's own multilib setup is out of scope, this project only takes individual GLFS pages as book sources for a plain 64-bit LFS/BLFS system). True of any non-multilib LFS box, not host-specific.
# rm -rf * &&
# meson setup --prefix=/usr       \
#             --buildtype=release \
#             --cross-file=lib32  \
#             -D hgl=false        \
#             .. &&
# 
# ninja

# --- block 4 --------------------------------------------------
#   ctx: Now as the root user:
#   REVIEWED [drop]: Installs the 32-bit build from block 3, which is dropped.
# DESTDIR=$PWD/DESTDIR ninja install    &&
# cp -vr DESTDIR/usr/lib32/* /usr/lib32 &&
# rm -rf DESTDIR                        &&
# ldconfig

