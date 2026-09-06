#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/xsoft/libreoffice.html
# title  : LibreOffice-26.2.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: g, libwps, libzmf, lp_solve, mdds, MyThes, odfvalidator, officeotron, Orcus, rhino, and
#   ctx: suitesparse (colamd) There are many optional dependencies not listed here. They can be
#   ctx: found in the download.lst file in the sources directory. Editor Notes:
#   ctx: https://wiki.linuxfromscratch.org/blfs/wiki/libreoffice Installation of LibreOffice
#   ctx: First, fix build failures introduced by the latest version of poppler:
patch -Np1 -i ../libreoffice-26.2.1.2-poppler_26.02-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Next, fix a bug with linking to zlib, fix a bug which would cause an install failure,
#   ctx: and prevent compression of man pages:
sed -i '/icuuc \\/a zlib\\'           writerperfect/Library_wpftdraw.mk &&
sed -i "/distro-install-file-lists/d" Makefile.in                       &&
sed -e "/gzip -f/d"   \
    -e "s|.1.gz|.1|g" \
    -i bin/distro-install-desktop-integration

# --- block 2 --------------------------------------------------
#   ctx: If you have downloaded the dictionaries, help and translations tarballs, create symlinks
#   ctx: to them from the source directory so they won't get downloaded again:
install -dm755 external/tarballs &&
ln -sv ../../../libreoffice-dictionaries-26.2.1.2.tar.xz external/tarballs/ &&
ln -sv ../../../libreoffice-help-26.2.1.2.tar.xz         external/tarballs/ &&
ln -sv ../../../libreoffice-translations-26.2.1.2.tar.xz external/tarballs/

# --- block 3 --------------------------------------------------
#   ctx: The instructions in the package unpack some tarballs into a location it cannot find
#   ctx: later. Create some symlinks to help the build system out:
ln -sv src/libreoffice-help-26.2.1.2/helpcontent2/ &&
ln -sv src/libreoffice-dictionaries-26.2.1.2/dictionaries/ &&
ln -sv src/libreoffice-translations-26.2.1.2/translations/

# --- block 4 --------------------------------------------------
#   ctx: ess, some packages will be downloaded (including the ones listed as recommended and
#   ctx: optional dependencies) if they are not present on the system. Because of this, build
#   ctx: time may vary from the published time more than usual. Due to the large size of the
#   ctx: package, you may prefer to install it in /opt, instead of /usr. Depending on your
#   ctx: choice, replace <PREFIX> by /usr or by /opt/libreoffice-26.2.1.2:
export LO_PREFIX=<PREFIX>

# --- block 5 --------------------------------------------------
#   ctx: find below, are just examples; you should change them to suit your needs - you might
#   ctx: want to read the "Command Explanations", further below, before proceeding. Note If you
#   ctx: set the ACLOCAL environment variable to support installing Xorg in /opt, you will need
#   ctx: to unset it for this package. If you are building on a 32 bit machine, CFLAGS is set to
#   ctx: -Os, which breaks the build. Prevent this by issuing:
case $(uname -m) in
   i?86) sed /-Os/d -i solenv/gbuild/platform/LINUX_INTEL_GCC.mk ;;
esac

# --- block 6 --------------------------------------------------
#   ctx: Prepare LibreOffice for compilation by running the following commands:
./autogen.sh --prefix=$LO_PREFIX         \
             --sysconfdir=/etc           \
             --with-vendor=BLFS          \
             --with-lang='fr en-GB'      \
             --with-help=html            \
             --with-myspell-dicts        \
             --without-junit             \
             --without-system-dicts      \
             --disable-dconf             \
             --disable-odk               \
             --disable-mariadb-sdbc      \
             --enable-release-build=yes  \
             --enable-python=system      \
             --with-jdk-home=/opt/jdk    \
             --with-system-boost         \
             --with-system-clucene       \
             --with-system-curl          \
             --with-system-epoxy         \
             --with-system-expat         \
             --with-system-glm           \
             --with-system-gpgmepp       \
             --with-system-graphite      \
             --with-system-harfbuzz      \
             --with-system-icu           \
             --with-system-jpeg          \
             --with-system-lcms2         \
             --with-system-libatomic_ops \
             --with-system-libtiff       \
             --with-system-libpng        \
             --with-system-libxml        \
             --with-system-libwebp       \
             --with-system-nss           \
             --with-system-odbc          \
             --with-system-openldap      \
             --with-system-openssl       \
             --with-system-poppler       \
             --with-system-postgresql    \
             --with-system-redland       \
             --with-system-zlib          \
             --with-system-zstd

# --- block 7 --------------------------------------------------
#   ctx: Build the package:
make build

# --- block 8 --------------------------------------------------
#   ctx: Now, as the root user:
make distro-pack-install

# --- block 9 --------------------------------------------------
#   ctx: If installed in /opt/libreoffice-26.2.1.2 some additional steps are necessary. Issue the
#   ctx: following commands as the root user:
if [ "$LO_PREFIX" != "/usr" ]; then

  # This symlink is necessary for the desktop menu entries
  ln -svf $LO_PREFIX/lib/libreoffice/program/soffice /usr/bin/libreoffice &&

  # Set up a generic location independent of version number
  ln -sfv $LO_PREFIX /opt/libreoffice &&

  # Icons
  mkdir -vp /usr/share/pixmaps &&
  for i in $LO_PREFIX/share/icons/hicolor/32x32/apps/*; do
    ln -svf $i /usr/share/pixmaps
  done &&

  # Desktop menu entries
  for i in $LO_PREFIX/lib/libreoffice/share/xdg/*; do
    ln -svf $i /usr/share/applications/libreoffice-$(basename $i)
  done &&

  # Man pages
  for i in $LO_PREFIX/share/man/man1/*; do
    ln -svf $i /usr/share/man/man1/
  done &&

  unset i
fi

# --- block 10 --------------------------------------------------
#   ctx: If you have installed desktop-file-utils-0.28, and you wish to update the MIME database,
#   ctx: issue, as the root user:
update-desktop-database

