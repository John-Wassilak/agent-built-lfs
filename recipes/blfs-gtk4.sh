#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/x/gtk4.html
# title  : GTK-4.20.3
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of GTK 4 Install GTK 4 by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr            \
            --buildtype=release      \
            -D broadway-backend=true \
            -D introspection=enabled \
            -D vulkan=enabled        \
            .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: If you have Gi-DocGen-2026.1 installed and wish to build the API documentation for this
#   ctx: package, issue:
sed "s@'doc'@& / 'gtk-4.20.3'@" -i ../docs/reference/meson.build &&
meson configure -D documentation=true                            &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To run the tests, issue:
env -u{GALLIUM_DRIVER,MESA_LOADER_DRIVER_OVERRIDE}          \
    LIBGL_ALWAYS_SOFTWARE=1 VK_LOADER_DRIVERS_SELECT='lvp*' \
    dbus-run-session meson test --setup x11                 \
                                --no-suite=headless

# --- block 3 --------------------------------------------------
#   ctx: If you are in a Wayland session, replace the one occurrence of x11 with wayland. Many
#   ctx: tests will fail if ~/.config/gtk-4.0/settings.ini exists and the gtk-modules line is not
#   ctx: commented out. Several other tests may fail for unknown reasons. On systems with NVIDIA
#   ctx: graphics cards, the tests may take significantly longer. Now, as the root user:
ninja install

# --- block 4 --------------------------------------------------
#   ctx: e icons that appear on the application's toolbar. If you have installed a GTK 4 theme
#   ctx: (e.g. the Adwaita theme built in GTK 4), an icon theme (such as oxygen-icons-6.1.0)
#   ctx: and/or a font (Dejavu fonts), you can set your preferences in
#   ctx: ~/.config/gtk-4.0/settings.ini, or the default system-wide configuration file (as the
#   ctx: root user), in /usr/share/gtk-4.0/settings.ini. For the local user, an example is:
mkdir -pv ~/.config/gtk-4.0
cat > ~/.config/gtk-4.0/settings.ini << "EOF"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = oxygen
gtk-font-name = DejaVu Sans 12
gtk-cursor-theme-size = 18
gtk-xft-antialias = 1
gtk-xft-hinting = 1
gtk-xft-hintstyle = hintslight
gtk-xft-rgba = rgb
gtk-cursor-theme-name = Adwaita
EOF

