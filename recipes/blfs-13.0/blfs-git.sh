#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/git.html
# title  : Git-2.53.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: to connect to a SMTP server with SSL encryption), and Systemd-259.1 (runtime, rebuilt
#   ctx: with Linux-PAM-1.7.2, for scheduling git maintenance jobs) Optional (to create the man
#   ctx: pages, html docs and other docs) xmlto-0.0.29 and asciidoc-10.2.1, and also dblatex (for
#   ctx: the PDF version of the user manual), and docbook2x to create info pages Installation of
#   ctx: Git Install Git by running the following commands:
./configure --prefix=/usr                   \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3           \
            --with-libpcre2                 &&
make

# --- block 1 --------------------------------------------------
#   ctx: You can build the man pages and/or html docs, or use downloaded ones. If you choose to
#   ctx: build them, use the next two instructions. If you have installed asciidoc-10.2.1 you can
#   ctx: create the html version of the man pages and other docs:
#   REVIEWED [drop]: 'make html' builds the HTML docs and requires asciidoc, which is not installed. The book gates it on 'If you have installed asciidoc'.
# make html

# --- block 2 --------------------------------------------------
#   ctx: If you have installed asciidoc-10.2.1 and xmlto-0.0.29 you can create the man pages:
#   REVIEWED [drop]: 'make man' builds the man pages and requires both asciidoc and xmlto, neither installed. We use the prebuilt git-manpages tarball instead (block 6).
# make man

# --- block 3 --------------------------------------------------
#   ctx: est suite can be run in parallel mode. To run the test suite, issue: GIT_UNZIP=nonexist
#   ctx: make test -k. The GIT_UNZIP setting prevents the test suite from using unzip, we need it
#   ctx: because in BLFS unzip is a symlink to bsdunzip which does not satisfy the assumption of
#   ctx: some tests cases. If any test case fails, the list of failed tests can be shown via make
#   ctx: -C t aggregate-results. Now, as the root user:
make perllibdir=/usr/lib/perl5/5.42/site_perl install

# --- block 4 --------------------------------------------------
#   ctx: If you created the man pages and/or html docs Install the man pages as the root user:
#   REVIEWED [drop]: 'make install-man' installs man pages built by block 2. Since we do not build them, there is nothing to install and the target would fail.
# make install-man

# --- block 5 --------------------------------------------------
#   ctx: Install the html docs as the root user:
#   REVIEWED [drop]: 'make install-html' installs HTML docs built by block 1. Same reason: not built, so nothing to install.
# make htmldir=/usr/share/doc/git-2.53.0 install-html

# --- block 6 --------------------------------------------------
#   ctx: If you downloaded the man pages and/or html docs If you downloaded the man pages untar
#   ctx: them as the root user:
tar -xf ../git-manpages-2.53.0.tar.xz \
    -C /usr/share/man --no-same-owner --no-overwrite-dir

# --- block 7 --------------------------------------------------
#   ctx: If you downloaded the html docs untar them as the root user:
#   REVIEWED [drop]: Untars git-htmldocs-2.53.0.tar.xz, which we deliberately did not download -- HTML documentation is not wanted and the tarball is large. The book presents it as an alternative to block 1/5, not an addition.
# mkdir -vp   /usr/share/doc/git-2.53.0 &&
# tar   -xf   ../git-htmldocs-2.53.0.tar.xz \
#       -C    /usr/share/doc/git-2.53.0 --no-same-owner --no-overwrite-dir &&
# 
# find        /usr/share/doc/git-2.53.0 -type d -exec chmod 755 {} \; &&
# find        /usr/share/doc/git-2.53.0 -type f -exec chmod 644 {} \;

# --- block 8 --------------------------------------------------
#   ctx: Reorganize text and html in the html-docs (both methods) For both methods, the html-docs
#   ctx: include a lot of plain text files. Reorganize the files as the root user:
#   REVIEWED [drop]: Reorganises the HTML doc tree that block 7 would have unpacked. With block 7 dropped the paths do not exist and the mv commands would fail.
# mkdir -vp /usr/share/doc/git-2.53.0/man-pages/{html,text}         &&
# mv        /usr/share/doc/git-2.53.0/{git*.adoc,man-pages/text}     &&
# mv        /usr/share/doc/git-2.53.0/{git*.,index.,man-pages/}html &&
# 
# mkdir -vp /usr/share/doc/git-2.53.0/technical/{html,text}         &&
# mv        /usr/share/doc/git-2.53.0/technical/{*.adoc,text}        &&
# mv        /usr/share/doc/git-2.53.0/technical/{*.,}html           &&
# 
# mkdir -vp /usr/share/doc/git-2.53.0/howto/{html,text}             &&
# mv        /usr/share/doc/git-2.53.0/howto/{*.adoc,text}            &&
# mv        /usr/share/doc/git-2.53.0/howto/{*.,}html               &&
# 
# sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.53.0/howto-index.html &&
# sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.53.0/howto-index.adoc

