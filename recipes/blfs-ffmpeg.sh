#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/ffmpeg.html
# title  : FFmpeg-8.0.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: iec61883, libilbc, libmodplug, libnut (Git checkout), librtmp, libssh, libtheora, libvpl
#   ctx: (for non-vaapi QuickSync) with one of Intel-MediaSDK (Haswell/4000 series or below) or
#   ctx: intel-onevpl (Broadwell/5000+), OpenAL, OpenCore AMR, rubberband, Srt, Schroedinger,
#   ctx: TwoLAME, vo-aaenc, vo-amrwbenc, and ZVBI Installation of FFmpeg First, apply a patch
#   ctx: that adds an API necessary for some packages to build:
patch -Np1 -i ../ffmpeg-8.0.1-chromium_method-1.patch

# --- block 1 --------------------------------------------------
#   ctx: Now add a fix from upstream to make ffmpeg compatible with SVT-AV1-4.0.0 and later:
sed -e '/adaptive/c\ param->aq_mode = 0;' \
    -i libavcodec/libsvtav1.c

# --- block 2 --------------------------------------------------
#   ctx: Install FFmpeg by running the following commands:
./configure --prefix=/usr        \
            --enable-gpl         \
            --enable-version3    \
            --enable-nonfree     \
            --disable-static     \
            --enable-shared      \
            --disable-debug      \
            --enable-libaom      \
            --enable-libass      \
            --enable-libfdk-aac  \
            --enable-libfreetype \
            --enable-libmp3lame  \
            --enable-libopus     \
            --enable-libvorbis   \
            --enable-libvpx      \
            --enable-libx264     \
            --enable-libx265     \
            --enable-openssl     \
            --enable-libdav1d    \
            --enable-libsvtav1   \
            --ignore-tests=enhanced-flv-av1,enhanced-flv-multitrack \
            --docdir=/usr/share/doc/ffmpeg-8.0.1 &&

make &&

gcc tools/qt-faststart.c -o tools/qt-faststart

# --- block 3 --------------------------------------------------
#   ctx: HTML documentation was built in the previous step. If you have texlive-20250308
#   ctx: installed and wish to build PDF and Postscript versions of the documentation, issue the
#   ctx: following commands:
#   REVIEWED [drop]: Optional PDF/PostScript documentation build (texi2pdf/texi2dvi/dvips) -- the book's own command has no 'if you have texlive' guard despite the prose framing, so it's unconditionally enabled by default and would fail outright: texlive is not installed anywhere in this project.
# pushd doc &&
# for DOCNAME in `basename -s .html *.html`
# do
#     texi2pdf -b $DOCNAME.texi &&
#     texi2dvi -b $DOCNAME.texi &&
# 
#     dvips    -o $DOCNAME.ps   \
#                 $DOCNAME.dvi
# done &&
# popd &&
# unset DOCNAME

# --- block 4 --------------------------------------------------
#   ctx: If you have Doxygen-1.16.1 installed and you wish to build (if --disable-doc was used)
#   ctx: or rebuild the html documentation, issue:
#   REVIEWED [drop]: Optional Doxygen API-doc rebuild -- same pattern as every other doc-tool trap this project has hit (alsa-lib, gdk-pixbuf, pango, json-c, popt, libassuan, gnupg): Doxygen is not installed.
# doxygen doc/Doxyfile

# --- block 5 --------------------------------------------------
#   ctx: The fate-suite tests include comparisons with installed files, and should not be run
#   ctx: before the package is installed. Therefore, if you desire to run them, instructions are
#   ctx: given further below. Now, as the root user:
make install &&

install -v -m755    tools/qt-faststart /usr/bin &&
install -v -m755 -d           /usr/share/doc/ffmpeg-8.0.1 &&
install -v -m644    doc/*.txt /usr/share/doc/ffmpeg-8.0.1

# --- block 6 --------------------------------------------------
#   ctx: If the PDF and Postscript documentation was built, issue the following commands, as the
#   ctx: root user, to install them:
#   REVIEWED [drop]: Installs the PDF/PostScript docs from block 3, which is dropped.
# install -v -m644 doc/*.pdf /usr/share/doc/ffmpeg-8.0.1 &&
# install -v -m644 doc/*.ps  /usr/share/doc/ffmpeg-8.0.1

# --- block 7 --------------------------------------------------
#   ctx: If you used doxygen to manually create the API documentation, install it by issuing the
#   ctx: following commands as the root user:
#   REVIEWED [drop]: Installs the Doxygen API docs from block 4, which is dropped.
# install -v -m755 -d /usr/share/doc/ffmpeg-8.0.1/api                     &&
# cp -vr doc/doxy/html/* /usr/share/doc/ffmpeg-8.0.1/api                  &&
# find /usr/share/doc/ffmpeg-8.0.1/api -type f -exec chmod -c 0644 \{} \; &&
# find /usr/share/doc/ffmpeg-8.0.1/api -type d -exec chmod -c 0755 \{} \;

# --- block 8 --------------------------------------------------
#   ctx: To properly test the installation you must have rsync-3.4.1 installed and follow the
#   ctx: instructions for the FFmpeg Automated Testing Environment (FATE). First, about 1 GB of
#   ctx: sample files used to run FATE are downloaded with the command:
#   REVIEWED [drop]: FFmpeg's FATE test suite, part 1: rsync-downloads ~1GB of sample files. Not auto-flagged by the testsuite classifier (an rsync invocation, not 'make check'/'make test'). rsync itself isn't installed in this project's stack at this point either, so it would fail outright even before the network/size concern.
# make fate-rsync SAMPLES=fate-suite/

# --- block 9 --------------------------------------------------
#   ctx: make fate-rsync ... command above to sync with the upstream repository. The download
#   ctx: size and time are drastically reduced by doing this. Estimated values in "Package
#   ctx: Information" do not include the download SBU. Some samples may have been removed in
#   ctx: newer versions, so in order to be sure local and server fate samples are identical when
#   ctx: you use previously saved samples, run the following command:
#   REVIEWED [drop]: FATE test suite, part 2 -- another rsync-based sample sync, paired with block 8.
# rsync -vrltLW  --delete --timeout=60 --contimeout=60 \
#       rsync://fate-suite.ffmpeg.org/fate-suite/ fate-suite/

# --- block 10 --------------------------------------------------
#   ctx: Next, execute FATE with the following commands (there are more than 5200 tests in the
#   ctx: suite):
#   REVIEWED [drop]: The actual FATE test suite run -- 'more than 5200 tests', explicitly not run anywhere else in this project.
# make fate THREADS=N SAMPLES=fate-suite/ | tee ../fate.log &&
# grep ^TEST ../fate.log | wc -l

