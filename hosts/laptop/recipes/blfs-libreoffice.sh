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
ln -sv /sources/libreoffice-extern/1725634df4bb3dcb1b2c91a6175f8789-GentiumBasic_1102.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/26b3e95ddf3d9c077c480ea45874b3b8-lp_solve_5.5.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/33e1e61fab06a547851ed308b4ffef42-dejavu-fonts-ttf-2.37.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/368f114c078f94214a308a74c7e991bc-crosextrafonts-20130214.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/5ade6ae2a99bc1e9e57031ca88d36dad-hyphen-2.8.8.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Agdasima-2.002.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Amiri-1.001.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Bacasime_Antique-2.000.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Belanosima-2.000.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Caprasimo-1.001.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/CoinMP-1.8.4.tgz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Lugrasimo-1.001.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Lumanosimo-1.010.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Lunasima-2.009.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoKufiArabic-v2.110.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoNaskhArabic-v2.021.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSans-v2.015.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansArabic-v2.010.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansArmenian-v2.008.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansGeorgian-v2.005.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansHebrew-v3.001.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansLao-v2.003.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSansLisu-v2.102.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSerif-v2.015.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSerifArmenian-v2.008.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSerifGeorgian-v2.003.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSerifHebrew-v2.004.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/NotoSerifLao-v2.003.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/ReemKufi-2.0.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/Scheherazade-2.100.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/afdko-4.0.3.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/alef-1.001.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/antlr4-cpp-runtime-4.13.2-source.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/box2d-2.4.1.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/c74b7223abe75949b4af367942d96c7a-crosextrafonts-carlito-20130920.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/cppunit-1.15.1.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/culmus-0.140.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/dragonbox-1.1.3.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/e7a384790b13c29113e22e596ade9687-LinLibertineG-20120116.zip external/tarballs/ &&
ln -sv /sources/libreoffice-extern/f543e6e2d7275557a839a164941c0a86e5f2c3f2a0042bfc434c88c6dde9e140-opens___.ttf external/tarballs/ &&
ln -sv /sources/libreoffice-extern/fast_float-8.2.2.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/frozen-1.2.0.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/hunspell-1.7.2.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/language-subtag-registry-2025-08-25.tar.bz2 external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libabw-0.1.3.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libcdr-0.1.8.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libcmis-0.6.2.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libe-book-0.1.3.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libeot-0.01.tar.bz2 external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libepubgen-0.1.1.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/liberation-fonts-ttf-2.1.5.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/liberation-narrow-fonts-ttf-1.07.6.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libetonyek-0.1.13.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libexttextcat-3.4.7.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libfreehand-0.1.2.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/liblangtag-0.6.8.tar.bz2 external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libmspub-0.1.4.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libmwaw-0.3.22.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libnumbertext-1.0.11.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libodfgen-0.1.8.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/liborcus-0.21.0.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libpagemaker-0.0.4.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libqxp-0.0.2.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libre-hebrew-1.0.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/librevenge-0.0.5.tar.bz2 external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libstaroffice-0.0.7.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libvisio-0.1.10.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libwpd-0.10.3.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libwpg-0.3.4.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libwps-0.4.14.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/libzmf-0.0.2.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/md4c-release-0.5.2.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/mdds-3.1.0.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/mythes-1.2.5.tar.xz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/pdfium-7471.tar.bz2 external/tarballs/ &&
ln -sv /sources/libreoffice-extern/phc-winner-argon2-20190702.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/xmlsec1-1.3.9.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/zxcvbn-c-2.6.tar.gz external/tarballs/ &&
ln -sv /sources/libreoffice-extern/zxing-cpp-2.3.0.tar.gz external/tarballs/

# --- block 3 --------------------------------------------------
#   ctx: The instructions in the package unpack some tarballs into a location it cannot find
#   ctx: later. Create some symlinks to help the build system out:
ln -sv src/libreoffice-help-26.2.1.2/helpcontent2/ &&
ln -sv src/libreoffice-dictionaries-26.2.1.2/dictionaries/

# --- block 4 --------------------------------------------------
#   ctx: ess, some packages will be downloaded (including the ones listed as recommended and
#   ctx: optional dependencies) if they are not present on the system. Because of this, build
#   ctx: time may vary from the published time more than usual. Due to the large size of the
#   ctx: package, you may prefer to install it in /opt, instead of /usr. Depending on your
#   ctx: choice, replace <PREFIX> by /usr or by /opt/libreoffice-26.2.1.2:
export LO_PREFIX=/usr
export container=lfsbuild-native

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
./autogen.sh --prefix=$LO_PREFIX \
           --sysconfdir=/etc \
           --with-vendor=BLFS \
           --with-lang=en-US \
           --with-help=html \
           --with-myspell-dicts \
           --without-junit \
           --without-system-dicts \
           --without-java \
           --disable-dconf \
           --disable-odk \
           --disable-mariadb-sdbc \
           --disable-postgresql-sdbc \
           --disable-firebird-sdbc \
           --disable-cups \
           --disable-dbus \
           --disable-gstreamer-1-0 \
           --disable-skia \
           --enable-release-build=yes \
           --enable-python=system \
           --with-system-boost \
           --with-system-clucene \
           --with-system-curl \
           --with-system-epoxy \
           --with-system-expat \
           --with-system-glm \
           --with-system-gpgmepp \
           --with-system-graphite \
           --with-system-harfbuzz \
           --with-system-icu \
           --with-system-jpeg \
           --with-system-lcms2 \
           --with-system-libatomic_ops \
           --with-system-libtiff \
           --with-system-libpng \
           --with-system-libxml \
           --with-system-libwebp \
           --with-system-nss \
           --with-system-odbc \
           --with-system-openldap \
           --with-system-openssl \
           --with-system-poppler \
           --with-system-redland \
           --with-system-zlib \
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
#   REVIEWED [drop]: Book's own text is explicitly conditional: 'If you have installed desktop-file-utils-0.28, and you wish to update the MIME database, issue...'. desktop-file-utils is not built on this host.
# update-desktop-database

