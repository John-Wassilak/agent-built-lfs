#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for zbar. The book's only mention of the
# name is the `-D zbar=enabled/disabled` switch on multimedia/gst10-plugins-bad.html
# (`grep -ril zbar book/` returns that one file), i.e. BLFS knows zbar exists as
# something gstreamer can link, and carries no page to build it.
#
# source: github.com/mchehab/zbar (the maintained fork; the original sourceforge
#   ZBar is dead), tag 0.23.93, released 2024-01-09 and still the newest tag.
#
# provenance: md5 3f69d17f6495de023b59b3539ce5e605, sha256
#   212dfab527894b8bcbcc7cd1d43d63f5604a07473d31a5f02889e372614ebe28, of the tag
#   archive github generates for 0.23.93. NOT a release asset: the 0.23.93 release
#   publishes no source tarball (only the 0.23.91/0.23.92 releases carry prebuilt
#   macos/ubuntu/windows binaries), so unlike libp11 there is no upstream-signed
#   artifact and no independent trust path here -- the archive and the hash both come
#   from github. Debian's own zbar packaging takes the same tag archive.
#
# rationale: operator asked for `zbarimg`, the command-line barcode/QR decoder
# (seq 335). It reads image files and prints what it decodes; `zbarimg foo.png`.
#
# Because the tag archive is a git export rather than a `make dist` tarball, there
# is no ./configure and no autogen.sh in it -- autoreconf -fi below generates them.
# That is why this is a hand() step rather than anything the extractor could produce.
set -e

# --with-imagemagick --without-graphicsmagick, together, for one reason: to make a
# missing Magick a HARD configure failure rather than a silently smaller install.
#
# zbarimg is not built unconditionally. Makefile.am:49 has
#
#     if HAVE_MAGICK
#     include $(srcdir)/zbarimg/Makefile.am.inc
#     endif
#
# and zbarimg.c loads every input file through MagickWand (libzbar itself only ever
# sees a raw Y800 buffer). With configure's defaults -- with_imagemagick="check",
# with_graphicsmagick="check" -- a host with neither installed does not fail. It
# takes the `test "x$with_graphicsmagick" = "xcheck"` branch at configure.ac:446,
# prints "ImageMagick/GraphicsMagick not detected. Several features will be
# disabled", sets with_imagemagick=no, and builds cleanly. The step would go green,
# the manifest would look plausible, and the one binary this package was added for
# would not exist.
#
# Passing --with-imagemagick alone does not close that hole: with_graphicsmagick is
# still "check", so the same branch still catches it. Only pinning BOTH -- IM yes, GM
# no -- leaves the AC_MSG_FAILURE at the end of that chain as the reachable branch,
# so a missing MagickWand stops the build at configure time. ImageMagick is seq 334,
# immediately before this step, precisely so it is there.
#
# --without-dbus is a deliberate narrowing, not a dependency we lack. dbus IS built
# here (seq 101), so configure's with_dbus="check" would have enabled it, and that
# is worth avoiding on this host:
#
#   zbarimg.c:320 initialises `int dbus = 1` and calls zbar_processor_request_dbus()
#   at line 419, i.e. dbus emission is ON by default and `--nodbus` is opt-out. What
#   it does is img_scanner.c:764, `conn = dbus_bus_get(DBUS_BUS_SYSTEM, &err)` --
#   the SYSTEM bus, not the session bus. Every payload zbarimg decodes gets
#   broadcast where any local user can read it, and QR codes routinely carry wifi
#   PSKs, OTP enrolment secrets and signed URLs.
#
#   The dbus build also installs dbus/org.linuxtv.Zbar.conf into
#   /etc/dbus-1/system.d (Makefile.am:91-92), a system-bus policy with
#   <policy context="default"><allow own="org.linuxtv.Zbar"/>, i.e. any user may
#   claim the name and receive those sends.
#
# Nothing asked for here needs it -- decoding an image file to stdout does not --
# and building without it removes both the code path and the policy file rather than
# relying on remembering --nodbus. If a future step wants zbar's dbus signalling,
# that is a deliberate rebuild with a reason of its own.
#
# The four --without flags below pin bindings that configure would otherwise decide
# from whatever happens to be installed, which is the failure mode the nextcloud
# tier already paid for once:
#   --without-python  python3 is installed, and with_python="auto" would build and
#                     install the python bindings into site-packages. Not asked for.
#   --without-gtk     gtk+-3.0.pc is present (seq 104), and with_gtk="auto" would
#                     build libzbargtk plus a second camera binary, zbarcam-gtk.
#   --without-qt      with_qt defaults to "yes". It looks for Qt5Core/Qt5X11Extras;
#                     this host has Qt6 in /opt/qt6 and no Qt5, so it would fall
#                     back to "no" on its own today -- pinned so that installing Qt5
#                     later cannot silently change what this recipe produces. (Its
#                     --with-qt6 path is marked "currently broken" upstream.)
#   --without-java    no JDK here, so it would self-disable; pinned for the same
#                     reason.
#
# --disable-doc: zbar builds its man pages with xmlto, which is not installed and
# whose chain (docbook-xml DTD + docbook-xsl, neither built on this host) is three
# steps for one man page. configure already auto-disables docs when XMLTO is empty
# (configure.ac:190); this makes that explicit so adding xmlto for some other reason
# later does not silently change this package's file list. `zbarimg --help` covers
# the usage. Add xmlto and drop this flag if zbarimg(1) is ever wanted.
#
# Video support is left at its default (on). It costs one extra binary, zbarcam,
# built from a single .c file against the already-built libzbar, and this machine
# has both the kernel API (/usr/include/linux/videodev2.h) and a webcam. libv4l2 is
# not installed, so configure warns "libv4l not detected. Install it to support more
# cameras!" and uses the raw V4L2 API -- a warning, not an error, and unrelated to
# zbarimg.
#
# Portable: names no device, no display, no GPU, no disk, no codec. Shared per
# CLAUDE.md's shared/host test.
autoreconf -fi

./configure --prefix=/usr             \
            --sysconfdir=/etc         \
            --with-imagemagick        \
            --without-graphicsmagick  \
            --without-dbus            \
            --without-python          \
            --without-gtk             \
            --without-qt              \
            --without-java            \
            --disable-doc             \
            --disable-static &&
make

make install

# The point of the step. configure can decide not to build zbarimg for reasons that
# are only a notice in a 900-line log, so assert the binary exists rather than
# trusting the exit status of `make install`.
test -x /usr/bin/zbarimg || { echo "FATAL: zbarimg was not installed"; exit 1; }

echo "### version"
zbarimg --version
pkg-config --modversion zbar
echo "### no dbus policy file installed"
ls /etc/dbus-1/system.d/org.linuxtv.Zbar.conf 2>/dev/null && \
    { echo "FATAL: built with dbus after all"; exit 1; } || echo "confirmed absent"
echo "### installed programs"
ls -1 /usr/bin/zbar*
