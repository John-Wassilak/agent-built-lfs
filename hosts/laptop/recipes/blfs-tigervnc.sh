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
sed -i "/FL_MINOR_VERSION/s/3/4/" CMakeLists.txt &&

# No Linux-PAM on this host (see the review reason). PAM is used in exactly two
# places: vncsession (the Xvnc session launcher) and libvnc's username/password
# validator. Drop the top-level REQUIRED check, skip unix/vncserver, stub the
# validator.
sed -i '/find_package(PAM REQUIRED)/d' CMakeLists.txt &&
sed -i '/add_subdirectory(vncserver)/d' unix/CMakeLists.txt &&
cat > common/rfb/UnixPasswordValidator.cxx << "EOF"
// Replaces upstream's PAM-based validator: this build has no Linux-PAM.
// Username/password security types (Plain, TLSPlain, X509Plain, RA2, RA2_256)
// always refuse; VncAuth and the TLS/RSA-AES types that wrap it are unaffected.
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <string>

#include <rfb/UnixPasswordValidator.h>

using namespace rfb;

std::string UnixPasswordValidator::displayName;

bool UnixPasswordValidator::validateInternal(SConnection * /* sc */,
                                             const char * /* username */,
                                             const char * /* password */,
                                             std::string &msg)
{
  msg = "Username/password authentication unavailable: built without PAM";
  return false;
}
EOF

# --- block 2 --------------------------------------------------
#   ctx: Install tigervnc by running the following commands:
# Build viewer, x0vncserver, vncpasswd, vncconfig
cmake -G "Unix Makefiles"          \
      -D CMAKE_INSTALL_PREFIX=/usr \
      -D CMAKE_BUILD_TYPE=Release  \
      -W no-dev . &&
make

# --- block 3 --------------------------------------------------
#   ctx: This package does not come with a test suite. Now, as the root user:
# Install viewer, x0vncserver, vncpasswd, vncconfig
make install &&
mv  /usr/share/doc/tigervnc /usr/share/doc/tigervnc-1.16.0

# --- block 4 --------------------------------------------------
#   ctx: tigervnc systemd aware for VNC sessions and allows desktop environments like GNOME to
#   ctx: autostart services once the VNC session is started. This configuration also gives the
#   ctx: added benefit of starting VNC Sessions on system startup. To set up the VNC server in
#   ctx: this fashion, follow these instructions. First, install a rudimentary Xsession file so
#   ctx: that the VNC server can initialize X sessions properly:
#   REVIEWED [drop]: Configures the book's vncserver@ Xvnc session (Xsession, vncserver.users, ~/.config/tigervnc/config, vncserver@:1). Not applicable: Xvnc and vncsession are not built on this host (blocks 1-3).
# install -vdm755 /etc/X11/tigervnc &&
# install -v -m755 ../Xsession /etc/X11/tigervnc

# --- block 5 --------------------------------------------------
#   ctx: Next, set up a user mapping in /etc/tigervnc/vncserver.users. This tells the VNC Server
#   ctx: which session is allocated to a user.
#   REVIEWED [drop]: Configures the book's vncserver@ Xvnc session (Xsession, vncserver.users, ~/.config/tigervnc/config, vncserver@:1). Not applicable: Xvnc and vncsession are not built on this host (blocks 1-3).
# echo ":1=$(whoami)" >> /etc/tigervnc/vncserver.users

# --- block 6 --------------------------------------------------
#   ctx: Next, set up a configuration file to tell vncserver which desktop environment should be
#   ctx: used and what display geometry should be used. There are several other options that can
#   ctx: be defined in this file, but they are outside the scope of BLFS.
#   REVIEWED [drop]: Configures the book's vncserver@ Xvnc session (Xsession, vncserver.users, ~/.config/tigervnc/config, vncserver@:1). Not applicable: Xvnc and vncsession are not built on this host (blocks 1-3).
# install -vdm 755 ~/.config/tigervnc &&
# cat > ~/.config/tigervnc/config << EOF
# # Begin ~/.config/tigervnc/config
# # The session must match one listed in /usr/share/xsessions.
# # Ensure that there are no spaces at the end of the lines.
# 
# session=lxqt
# geometry=1024x768
# 
# # End ~/.config/tigervnc/config
# EOF

# --- block 7 --------------------------------------------------
#   ctx: To start the VNC Server, run the following command:
#   REVIEWED [drop]: Configures the book's vncserver@ Xvnc session (Xsession, vncserver.users, ~/.config/tigervnc/config, vncserver@:1). Not applicable: Xvnc and vncsession are not built on this host (blocks 1-3).
# systemctl start vncserver@:1

# --- block 8 --------------------------------------------------
#   ctx: To start the VNC Server when the system boots, run the following command:
#   REVIEWED [drop]: Configures the book's vncserver@ Xvnc session (Xsession, vncserver.users, ~/.config/tigervnc/config, vncserver@:1). Not applicable: Xvnc and vncsession are not built on this host (blocks 1-3).
# systemctl enable vncserver@:1

