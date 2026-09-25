#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/tigervnc.html
# title  : Tigervnc-1.16.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: c/Xsession Tigervnc Dependencies Required CMake-4.2.3, FLTK-1.4.4, GnuTLS-3.8.12,
#   ctx: libgcrypt-1.12.0, libjpeg-turbo-3.1.3, Pixman-0.46.4, Systemd-259.1 (with
#   ctx: Linux-PAM-1.7.2), Xorg Applications, xinit-1.4.4, and Xorg Legacy Fonts Recommended
#   ctx: ImageMagick-7.1.2-13 Optional FFmpeg-8.0.1 Installation of Tigervnc First, make
#   ctx: adjustments to the configuration files to make them compatible with LFS systems:
patch -Np1 -i ../tigervnc-1.16.0-configuration_fixes-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Now, make the package consistent with fltk-1.4.1 and later:
sed -i "/FL_MINOR_VERSION/s/3/4/" CMakeLists.txt

# --- block 2 --------------------------------------------------
#   ctx: Install tigervnc by running the following commands:
# Put code in place
mkdir -p unix/xserver &&
tar -xf ../xorg-server-21.1.21.tar.xz \
    --strip-components=1              \
    -C unix/xserver                   &&
( cd unix/xserver &&
  patch -Np1 -i ../xserver21.patch ) &&

# Build viewer
cmake -G "Unix Makefiles"          \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -W no-dev . &&
make &&

# Build server
pushd unix/xserver &&
  autoreconf -fiv  &&

  CPPFLAGS="-I/usr/include/drm"       \
  ./configure $XORG_CONFIG            \
      --disable-xwayland    --disable-dri        --disable-dmx         \
      --disable-xorg        --disable-xnest      --disable-xvfb        \
      --disable-xwin        --disable-xephyr     --disable-kdrive      \
      --disable-devel-docs  --disable-config-hal --disable-config-udev \
      --disable-unit-tests  --disable-selective-werror                 \
      --disable-static      --enable-dri3                              \
      --without-dtrace      --enable-dri2        --enable-glx          \
      --with-pic &&
  make  &&
popd

# --- block 3 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
#Install viewer
make install &&
mv  /usr/share/doc/tigervnc /usr/share/doc/tigervnc-1.16.0

#Install server
( cd unix/xserver/hw/vnc && make install ) &&

[ -e /usr/bin/Xvnc ] || ln -svf $XORG_PREFIX/bin/Xvnc /usr/bin/Xvnc

# --- block 4 --------------------------------------------------
#   ctx: tigervnc systemd aware for VNC sessions and allows desktop environments like GNOME to
#   ctx: autostart services once the VNC session is started. This configuration also gives the
#   ctx: added benefit of starting VNC Sessions on system startup. To set up the VNC server in
#   ctx: this fashion, follow these instructions. First, install a rudimentary Xsession file so
#   ctx: that the VNC server can initialize X sessions properly:
install -vdm755 /etc/X11/tigervnc &&
install -v -m755 ../Xsession /etc/X11/tigervnc

# --- block 5 --------------------------------------------------
#   ctx: Next, set up a user mapping in /etc/tigervnc/vncserver.users. This tells the VNC Server
#   ctx: which session is allocated to a user.
echo ":1=$(whoami)" >> /etc/tigervnc/vncserver.users

# --- block 6 --------------------------------------------------
#   ctx: Next, set up a configuration file to tell vncserver which desktop environment should be
#   ctx: used and what display geometry should be used. There are several other options that can
#   ctx: be defined in this file, but they are outside the scope of BLFS.
install -vdm 755 ~/.config/tigervnc &&
cat > ~/.config/tigervnc/config << EOF
# Begin ~/.config/tigervnc/config
# The session must match one listed in /usr/share/xsessions.
# Ensure that there are no spaces at the end of the lines.

session=lxqt
geometry=1024x768

# End ~/.config/tigervnc/config
EOF

# --- block 7 --------------------------------------------------
#   ctx: To start the VNC Server, run the following command:
systemctl start vncserver@:1

# --- block 8 --------------------------------------------------
#   ctx: To start the VNC Server when the system boots, run the following command:
systemctl enable vncserver@:1

