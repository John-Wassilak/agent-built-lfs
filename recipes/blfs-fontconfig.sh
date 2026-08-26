#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/fontconfig.html
# title  : Fontconfig-2.17.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e. The system certificate store may need to be set up with make-ca-1.16.1 before testing
#   ctx: this package. Note If you have DocBook Utils installed and you remove the --disable-docs
#   ctx: parameter from the configure command below, you must also have SGMLSpm-1.1 and
#   ctx: texlive-20250308 installed, or the Fontconfig build will fail. Installation of
#   ctx: Fontconfig Install Fontconfig by running the following commands:
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --localstatedir=/var \
            --disable-docs       \
            --docdir=/usr/share/doc/fontconfig-2.17.1 &&
make

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: make check. One test is known to fail if the kernel does not
#   ctx: support user namespaces. Some tests will download some font files via Internet, but will
#   ctx: be unable to retrieve the files and will fail the test. Now, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: If you did not remove the --disable-docs parameter from the configure command, you can
#   ctx: install the pre-generated documentation by using the following commands as the root
#   ctx: user:
install -v -dm755 \
        /usr/share/{man/man{1,3,5},doc/fontconfig-2.17.1} &&
install -v -m644 fc-*/*.1         /usr/share/man/man1 &&
install -v -m644 doc/*.3          /usr/share/man/man3 &&
install -v -m644 doc/fonts-conf.5 /usr/share/man/man5 &&
install -v -m644 doc/*.{pdf,sgml,txt,html} \
                                  /usr/share/doc/fontconfig-2.17.1

