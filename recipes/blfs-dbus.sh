#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/dbus.html
# title  : dbus-1.16.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: hed by D-Bus session daemon as systemd user services); For the tests: D-Bus
#   ctx: Python-1.4.0, PyGObject-3.54.5, and Valgrind-3.26.0; for documentation: Doxygen-1.16.1,
#   ctx: xmlto-0.0.29, Ducktype, and Yelp Tools Installation of D-Bus Install D-Bus by running
#   ctx: the following commands (you may wish to review the meson_options.txt file first and add
#   ctx: any additional desired options to the meson setup line below):
mkdir build &&
cd    build &&

meson setup --prefix=/usr          \
            --buildtype=release    \
            --wrap-mode=nofallback \
            .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: See below for test instructions. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: If you are using a DESTDIR install, dbus-daemon-launch-helper needs to be fixed
#   ctx: afterwards. Issue, as root user:
chown -v root:messagebus /usr/libexec/dbus-daemon-launch-helper &&
chmod -v      4750       /usr/libexec/dbus-daemon-launch-helper

# --- block 3 --------------------------------------------------
#   ctx: Finally, still as the root user, rename the documentation directory (it only exists if
#   ctx: the optional dependencies are satisfied for at least one documentation format) to make
#   ctx: it versioned:
if [ -e /usr/share/doc/dbus ]; then
  rm -rf /usr/share/doc/dbus-1.16.2    &&
  mv -v  /usr/share/doc/dbus{,-1.16.2}
fi

# --- block 4 --------------------------------------------------
#   ctx: from a local session with bus address. To run the standard tests issue ninja test. If
#   ctx: you want to run the unit regression tests, meson requires additional parameters which
#   ctx: expose additional functionality in the binaries that are not intended to be used in a
#   ctx: production build of D-Bus. If you would like to run the tests, issue the following
#   ctx: commands (for the tests, you don't need to build the docs):
#   REVIEWED [drop]: Optional intrusive/assert test-suite run, not wanted.
# meson configure -D asserts=true -D intrusive_tests=true &&
# ninja test

# --- block 5 --------------------------------------------------
#   ctx: tc/dbus-1/session-local.conf and/or /etc/dbus-1/system-local.conf and make any desired
#   ctx: changes to these files. If any package installs a D-Bus .service file outside of the
#   ctx: standard /usr/share/dbus-1/services directory, that directory should be added to the
#   ctx: local session configuration. For instance, /usr/local/share/dbus-1/services can be added
#   ctx: by performing the following commands as the root user:
#   REVIEWED [drop]: Example local-session config snippet from the book text, not an install step.
# cat > /etc/dbus-1/session-local.conf << "EOF"
# <!DOCTYPE busconfig PUBLIC
#  "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
#  "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
# <busconfig>
# 
#   <!-- Search for .service files in /usr/local -->
#   <servicedir>/usr/local/share/dbus-1/services</servicedir>
# 
# </busconfig>
# EOF

# --- block 6 --------------------------------------------------
#   ctx: ent. The syntax would be similar to the example in the ~/.xinitrc file. The examples
#   ctx: shown previously use dbus-launch to specify a program to be run. This has the benefit
#   ctx: (when also using the --exit-with-x11 parameter) of stopping the session daemon when the
#   ctx: specified program is stopped. You can also start the session daemon in your system or
#   ctx: personal startup scripts by adding the following lines:
#   REVIEWED [drop]: Example ~/.xinitrc snippet (eval dbus-launch), not an install step -- would hang a non-interactive batch build.
# # Start the D-Bus session daemon
# eval `dbus-launch`
# export DBUS_SESSION_BUS_ADDRESS

# --- block 7 --------------------------------------------------
#   ctx: This method will not stop the session daemon when you exit your shell, therefore you
#   ctx: should add the following line to your ~/.bash_logout file:
#   REVIEWED [drop]: Example ~/.bash_logout snippet, not an install step.
# # Kill the D-Bus session daemon
# kill $DBUS_SESSION_BUS_PID

