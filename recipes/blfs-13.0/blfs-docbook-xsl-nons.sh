#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/pst/docbook-xsl.html
# title  : docbook-xsl-nons-1.79.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: 5 (to produce “webhelp” documents), libxslt-1.1.45 (or any other XSLT processor), to
#   ctx: process Docbook documents, Ruby-4.0.1 (to utilize the “epub” stylesheets), Zip-3.0 (to
#   ctx: produce “epub3” documents), and Saxon6 and Xerces2 Java (used with apache-ant-1.10.15 to
#   ctx: produce “webhelp” documents) Installation of DocBook XSL Stylesheets First, fix a
#   ctx: problem that causes stack overflows when doing recursion:
patch -Np1 -i ../docbook-xsl-nons-1.79.2-stack_fix-1.patch

# --- block 1 --------------------------------------------------
#   ctx: If you downloaded the optional documentation tarball, unpack it with the following
#   ctx: command:
#   REVIEWED [drop]: The book's own condition: 'If you downloaded the optional documentation tarball, unpack it'. docbook-xsl-doc-1.79.2 is listed under Optional downloads and was not fetched; the stylesheets install and catalog entries (blocks 2 and 4) do not depend on it.
# tar -xf ../docbook-xsl-doc-1.79.2.tar.bz2 --strip-components=1

# --- block 2 --------------------------------------------------
#   ctx: BLFS does not install the required packages to run the test suite and provide meaningful
#   ctx: results. Install DocBook XSL Stylesheets by running the following commands as the root
#   ctx: user:
install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
         highlighting html htmlhelp images javahelp lib manpages params  \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5                                          \
    /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&

ln -svf VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl &&

install -v -m644 -D README \
                    /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt &&

install -v -m644    RELEASE-NOTES* NEWS* \
                    /usr/share/doc/docbook-xsl-nons-1.79.2

# --- block 3 --------------------------------------------------
#   ctx: If you downloaded the optional documentation tarball, install the documentation by
#   ctx: issuing the following command as the root user:
#   REVIEWED [drop]: Installs the documentation unpacked by block 1, which is dropped for the same reason: 'If you downloaded the optional documentation tarball, install the documentation'. Without it doc/ holds nothing to copy.
# cp -v -R doc/* /usr/share/doc/docbook-xsl-nons-1.79.2

# --- block 4 --------------------------------------------------
#   ctx: Configuring DocBook XSL Stylesheets Config Files /etc/xml/catalog Configuration
#   ctx: Information Create (or append) and populate the XML catalog file using the following
#   ctx: commands as the root user (both http and https forms are used because upstream have had
#   ctx: both in their documentation):
(set -e

 install -v -d -m755 /etc/xml
 [ -e /etc/xml/catalog ] || xmlcatalog --noout --create /etc/xml/catalog

 for uri in http{,s}://cdn.docbook.org/release/xsl-nons/{1.79.2,current} \
            http://docbook.sourceforge.net/release/xsl/current; do
   for rewrite in System URI; do
     xmlcatalog --noout --add "rewrite$rewrite"             \
       "$uri"                                               \
       "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
       /etc/xml/catalog
   done
 done)

# --- block 5 --------------------------------------------------
#   ctx: Occasionally, you may find the need to install other versions of the XSL stylesheets as
#   ctx: some projects reference a specific version. One example is BLFS-6.0, which required the
#   ctx: 1.67.2 version. In these instances you should install any other required version in its
#   ctx: own versioned directory and create catalog entries as follows (substitute the desired
#   ctx: version number for <version>):
#   REVIEWED [drop]: A template, not a command: the book says to 'substitute the desired version number for <version>' when a project needs another stylesheet version installed alongside. Run literally it would add catalog entries for a directory named xsl-stylesheets-<version>. Nothing in this closure needs a second version.
# xmlcatalog --noout --add "rewriteSystem"                          \
#            "http://docbook.sourceforge.net/release/xsl/<version>" \
#            "/usr/share/xml/docbook/xsl-stylesheets-<version>"     \
#            /etc/xml/catalog &&
# 
# xmlcatalog --noout --add "rewriteURI"                             \
#            "http://docbook.sourceforge.net/release/xsl/<version>" \
#            "/usr/share/xml/docbook/xsl-stylesheets-<version>"     \
#            /etc/xml/catalog

