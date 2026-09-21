#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for redshift.
# source: github.com/jonls/redshift/releases/download/v1.12/redshift-1.12.tar.xz --
# the real uploaded release asset, not GitHub's auto-generated git-tag source archive
# (same URL path, different asset): the latter has no generated `configure` at all
# (confirmed via a real failure), and regenerating it via the shipped `bootstrap`
# script needs intltool (itself needing the Perl XML::Parser CPAN module, not
# otherwise built anywhere in this project) -- the real release tarball avoids that
# whole chain since it already carries `configure` pre-generated.
# Rationale: X11 blue-light filter, wlsunset's replacement after
# abandoning Hyprland/Wayland (see AWESOME-X11-PLAN.md Phase 3).
# --disable-gui/--disable-geoclue2/--disable-drm: no GTK tray icon or
# automatic geolocation wanted (matches wlsunset's original config,
# which used a fixed lat/long); DRM adjustment method is the Wayland
# path, irrelevant now. --enable-randr/--enable-vidmode: the two X11
# gamma-adjustment methods actually usable here. --disable-nls: even the pre-
# generated configure (see the release-tarball note above) still probes for
# intltool-update at *run* time when NLS/translations are requested (the AM_GNU_
# GETTEXT macro's own default) -- confirmed via a real failure ("Your intltool is
# too old" -- actually just missing). No translations needed for this single-user,
# English-language box; --disable-nls is that same macro's own documented opt-out.
#
# --disable-nls alone isn't enough, though: configure's AC_PROG_INTLTOOL check runs
# unconditionally (before and independent of the NLS check) and shells out directly
# to `intltool-update --version` with no override variable -- confirmed via a real
# failure ("intltool-update: command not found" then "Your intltool is too old" from
# the resulting empty version string). Since --disable-nls means intltool-update is
# never actually invoked for real translation processing afterward, stubs that only
# satisfy configure's own PATH/--version probes (intltool-update, plus intltool-merge/
# -extract which a later AC_PATH_PROG check also demanded: "The intltool scripts were
# not found") are safe: the same class of fix as blfs-rust's own fake-git wrapper for
# its (also-skipped) test suite.
mkdir -p /tmp/fake-intltool
cat > /tmp/fake-intltool/intltool-update << "EOF"
#!/bin/bash
echo "intltool-update (dummy) 0.51.0"
EOF
cat > /tmp/fake-intltool/intltool-merge << "EOF"
#!/bin/bash
exit 0
EOF
cat > /tmp/fake-intltool/intltool-extract << "EOF"
#!/bin/bash
exit 0
EOF
chmod +x /tmp/fake-intltool/intltool-update /tmp/fake-intltool/intltool-merge /tmp/fake-intltool/intltool-extract
export PATH="/tmp/fake-intltool:$PATH"

./configure --prefix=/usr --disable-geoclue2 --disable-gui --disable-drm --enable-randr --enable-vidmode --disable-nls
make
make install
