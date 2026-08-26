#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/libxml2.html
# title  : libxml2-2.15.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .1 SBU (Using parallelism=4; with tests and documentation) Additional Downloads Optional
#   ctx: Test Suite: https://www.w3.org/XML/Test/xmlts20130923.tar.gz - This enables make check
#   ctx: to do complete testing. libxml2 Dependencies Recommended ICU-78.2 Optional (for
#   ctx: generating the documentation) Doxygen-1.16.1 and libxslt-1.1.45 Installation of libxml2
#   ctx: First, remove an unnecessary call to git in meson.build:
sed -i "/'git'/,+3d" meson.build

# --- block 1 --------------------------------------------------
#   ctx: Install libxml2 by running the following commands:
mkdir build &&
cd    build &&

meson setup ..           \
      --prefix=/usr      \
      -D history=enabled \
      -D icu=enabled     &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: If you wish to build and install the manual pages and the documentation, you should have
#   ctx: libxslt-1.1.45 and Doxygen-1.16.1 installed, and run:
#   REVIEWED [drop]: Reconfigures with docs=enabled, needs doxygen (not installed) -- 'Program doxygen not found', discovered when the build failed. One-level policy: docs generation, not needed.
# sed -e "/^dir_doc/s/\$/ + '-' + meson.project_version()/" \
#     -i ../meson.build                                     &&
# meson configure -D docs=enabled                           &&
# ninja

# --- block 3 --------------------------------------------------
#   ctx: If you downloaded the test suite, issue the following command:
#   REVIEWED [drop]: Fetches the optional test-suite tarball (xmlts20130923.tar.gz), not staged since the test suite is not being run.
# tar xf ../../xmlts20130923.tar.gz -C ..

# --- block 4 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Note The tests use http://localhost/ to test
#   ctx: parsing of external entities. If the machine where you run the tests serves as a web
#   ctx: site, the tests may hang, depending on the content of the file served. It is therefore
#   ctx: recommended to shut down the server during the tests, as the root user:
#   REVIEWED [drop]: Test-suite step: stop a running httpd before running libxml2's test suite (which uses port 80). httpd is not installed on this system and the test suite is not being run.
# systemctl stop httpd.service

# --- block 5 --------------------------------------------------
#   ctx: Now, as the root user:
ninja install

# --- block 6 --------------------------------------------------
#   ctx: against the static library for the project, including the references to the ICU-78.2
#   ctx: libraries. That would be pointless because we only install the shared library. To make
#   ctx: things worse, that may cause some packages using libxml2 to be unnecessarily linked
#   ctx: against some ICU-78.2 library, then those packages will need a rebuild if ICU is
#   ctx: upgraded to a new major version. Fix this by issuing, as root:
sed "s/--static/--shared/" -i /usr/bin/xml2-config

