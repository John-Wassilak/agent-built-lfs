#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/poppler.html
# title  : Poppler-26.02.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ommended Boost-1.90.0, Cairo-1.18.4, gpgmepp-2.0.0, Little CMS-2.18,
#   ctx: libjpeg-turbo-3.1.3, libpng-1.6.55, libtiff-4.7.1, nss-3.120.1, OpenJPEG-2.5.4, and
#   ctx: Qt-6.10.2 (required for PDF support in okular-25.12.2) Optional cURL-8.18.0,
#   ctx: gdk-pixbuf-2.44.5, git-2.53.0 (for downloading test files), GTK-Doc-1.35.1 and
#   ctx: GTK-3.24.51 Installation of Poppler Now, install Poppler by running the following
#   ctx: commands:
mkdir build                         &&
cd    build                         &&

cmake -D CMAKE_BUILD_TYPE=Release   \
      -D CMAKE_INSTALL_PREFIX=/usr  \
      -D TESTDATADIR=$PWD/testfiles \
      -D ENABLE_QT5=OFF             \
      -D ENABLE_UNSTABLE_API_ABI_HEADERS=ON \
      -D ENABLE_LIBOPENJPEG=none    \
      -G Ninja ..                   &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: In order to run the test suite, some testcases are needed and can be obtained only from
#   ctx: a git repository. The command to download them is: git clone --depth 1
#   ctx: https://gitlab.freedesktop.org/poppler/test.git testfiles. Then issue:
#   ctx: LC_ALL=en_US.UTF-8 ninja test. Now, as the root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: To install the documentation, run the following commands as root:
install -v -m755 -d           /usr/share/doc/poppler-26.02.0 &&
cp -vr ../glib/reference/html /usr/share/doc/poppler-26.02.0

# --- block 3 --------------------------------------------------
#   ctx: Poppler Data If you downloaded the additional encoding data package, install it by
#   ctx: issuing the following commands:
#   REVIEWED [drop]: Book's own text is explicitly conditional: 'If you downloaded the additional encoding data package, install it by issuing the following commands'. The poppler-data-0.4.12 tarball (CJK/Cyrillic encoding files, listed as an Additional Download, not Required/Recommended) was not fetched -- nothing in this project's PDF workflow needs CJK/Cyrillic PDF rendering specifically, and it's a separate optional download the book itself frames as skippable.
# tar -xf ../../poppler-data-0.4.12.tar.gz &&
# cd poppler-data-0.4.12

# --- block 4 --------------------------------------------------
#   ctx: Now, as the root user:
#   REVIEWED [drop]: Installs the poppler-data package from block 3, which is dropped for the same reason -- the tarball was never extracted so poppler-data-0.4.12/ doesn't exist.
# make prefix=/usr install

