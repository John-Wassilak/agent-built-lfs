#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/x/gtk3.html
# title  : GTK-3.24.52
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: nual pages), Wayland-1.26.0, and wayland-protocols-1.49 Recommended (Required if
#   ctx: building GNOME) GLib-2.88.3 (with GObject Introspection) Optional colord-1.4.8,
#   ctx: Cups-2.4.19, Evince-48.4 (runtime for the print previewer), GTK-Doc-1.36.1,
#   ctx: libcloudproviders-0.3.6, PyAtSpi2-2.58.2 (for tests), sassc-3.6.2, tinysparql-3.11.1,
#   ctx: and PAPI Installation of GTK3 Install GTK3 by running the following commands:
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D man=false         \
      -D broadway_backend=true \
      -D x11_backend=true \
      -D wayland_backend=false &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results you need a graphical session, then issue dbus-run-session ninja
#   ctx: test. One test, gtk:a11y / tree-relationships, is known to fail with a recent librsvg
#   ctx: release. Another test, gtk:reftest treeview-fixed-height.ui, is known to fail due to
#   ctx: small output differences compared to what the test suite expects. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: Note If you installed the package on to your system using a “DESTDIR” method, an
#   ctx: important file was not installed and must be copied and/or generated. Generate it using
#   ctx: the following command as the root user:
#   REVIEWED [drop]: DESTDIR-only caveat; not applicable.
# gtk-query-immodules-3.0 --update-cache

# --- block 3 --------------------------------------------------
#   ctx: Note If you installed the package to your system using a “DESTDIR” method,
#   ctx: /usr/share/glib-2.0/schemas/gschemas.compiled was not updated/created. Create (or
#   ctx: update) the file using the following command as the root user:
#   REVIEWED [drop]: DESTDIR-only caveat; not applicable.
# glib-compile-schemas /usr/share/glib-2.0/schemas

# --- block 4 --------------------------------------------------
#   ctx: hange the icons that appear on the application's toolbar. If you have installed a GTK3
#   ctx: theme (e.g. the Adwaita theme built in GTK3), an icon theme (such as
#   ctx: oxygen-icons-6.29.0) and/or a font (Dejavu fonts), you can set your preferences in
#   ctx: ~/.config/gtk-3.0/settings.ini, or the default system wide configuration file (as the
#   ctx: root user), in /etc/gtk-3.0/settings.ini. For the local user an example is:
mkdir -vp ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << "EOF"
[Settings]
gtk-theme-name = Adwaita
gtk-icon-theme-name = oxygen
gtk-font-name = DejaVu Sans 12
gtk-cursor-theme-size = 18
gtk-toolbar-style = GTK_TOOLBAR_BOTH_HORIZ
gtk-xft-antialias = 1
gtk-xft-hinting = 1
gtk-xft-hintstyle = hintslight
gtk-xft-rgba = rgb
gtk-cursor-theme-name = Adwaita
EOF

# --- block 5 --------------------------------------------------
#   ctx: gs keys, some with default values. You can find them at Settings: GTK3 Reference Manual.
#   ctx: There are many more themes available at https://www.gnome-look.org/browse/ and other
#   ctx: places. As part of GTK-3.0's redesign, the scroll bar buttons are no longer visible on
#   ctx: the scrollbar in many applications. If this functionality is desired, modify the gtk.css
#   ctx: file and restore them using the following command:
cat > ~/.config/gtk-3.0/gtk.css << "EOF"
*  {
   -GtkScrollbar-has-backward-stepper: 1;
   -GtkScrollbar-has-forward-stepper: 1;
}
EOF

