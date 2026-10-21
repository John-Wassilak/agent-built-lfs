#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.1-systemd book.
# source : book/blfs-13.1/general/dtc.html
# title  : dtc-1.8.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ckage Information Download (HTTP):
#   ctx: https://kernel.org/pub/software/utils/dtc/dtc-1.8.1.tar.xz Download MD5 sum:
#   ctx: 9753bdbf18763efef1f5ae8c0cecb5f6 Download size: 176 KB Estimated disk space required: 14
#   ctx: MB (with tests) Estimated build time: 0.2 SBU (with tests) Dtc Dependencies Optional
#   ctx: libyaml-0.2.5, SWIG-4.5.0, and texlive-20260301 Installation of Dtc Install dtc by
#   ctx: running the following commands:
mkdir build &&
cd    build &&

meson setup ..                 \
      --prefix=/usr            \
      --buildtype=release      \
      --default-library=shared \
      -D python=disabled       &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: meson configure -D werror=false && ninja test. Now, as the
#   ctx: root user:
ninja install

# --- block 2 --------------------------------------------------
#   ctx: If you have texlive-20260301 installed, you can build the PDF format of the
#   ctx: documentation by issuing the following command:
#   REVIEWED [drop]: BLFS 13.1 general/dtc.html: PDF documentation build, conditional on texlive-20260301 ('If you have texlive-20260301 installed'). texlive is not built here.
# pushd ../Documentation
#   latexmk -bibtex --pdf dtc-paper &&
#   latexmk -bibtex --pdf dtc-paper -c
# popd

# --- block 3 --------------------------------------------------
#   ctx: To install the documentation, as the root user issue the following command:
cp -R ../Documentation -T /usr/share/doc/dtc-1.8.1

# --- block 4 --------------------------------------------------
#   ctx: If you have installed SWIG-4.5.0 and you wish to install the Python 3 bindings of this
#   ctx: package, fix the code for the compatibility with SWIG 4.5.0 or newer first:
#   REVIEWED [drop]: BLFS 13.1 general/dtc.html: SWIG compatibility sed for the Python bindings, conditional on SWIG-4.5.0 being installed. SWIG is not built, and qemu links the C libfdt, not the Python module.
# sed -e 's/PyString_FromString/PyUnicode_FromString/' \
#     -e 's/PyString_AsString/PyBytes_AsString/'       \
#     -e 's/PyInt_AsLong/PyLong_AsLong/'               \
#     -i ../pylibfdt/libfdt.i

# --- block 5 --------------------------------------------------
#   ctx: Build the Python 3 module:
#   REVIEWED [drop]: BLFS 13.1 general/dtc.html: builds the optional Python 3 libfdt wheel; same SWIG condition as block 4. Nothing here imports libfdt from Python.
# pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir ..

# --- block 6 --------------------------------------------------
#   ctx: As the root user, install the Python 3 module:
#   REVIEWED [drop]: BLFS 13.1 general/dtc.html: installs the Python wheel block 5 would have built. Dropped with it.
# pip3 install --no-index --find-links dist --no-user libfdt

