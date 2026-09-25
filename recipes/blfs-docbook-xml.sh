#!/bin/bash
# HAND-AUTHORED recipe -- the book page pst/docbook.html (BLFS 13.0) covers this
# package, but its source is docbook-xml-4.5.zip, a zip with no top-level directory.
# lfsbuild unpacks with `tar -xf` and finds the source dir with `tar -tf`, and neither
# reads it, so the step has no tarball and this recipe unzips into its own scratch
# directory. The install commands after the unzip are the book's own.
# rationale: itstool's only Required dependency besides lxml, and itstool is
# AppStream's (GIMP's closure, seq 341-361).
# md5 03083e288e87a7e829e437358da7ef9e, matching the book.
set -e

SRC=/sources/docbook-xml-4.5.zip
WORK=$(mktemp -d /tmp/docbook-xml-4.5.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"
unzip -q "$SRC"

install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5 &&
install -v -d -m755 /etc/xml                           &&
cp -v -af --no-preserve=ownership                      \
    catalog.xml docbook.cat *.dtd ent/ *.mod           \
    /usr/share/xml/docbook/xml-dtd-4.5

xmlcatalog --noout --add "rewriteSystem"        \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /usr/share/xml/docbook/xml-dtd-4.5/catalog.xml &&

xmlcatalog --noout --add "rewriteURI"           \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /usr/share/xml/docbook/xml-dtd-4.5/catalog.xml

if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi &&

xmlcatalog --noout --add "delegatePublic"                   \
    "-//OASIS//ENTITIES DocBook XML"                        \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
    /etc/xml/catalog                                        &&

xmlcatalog --noout --add "delegatePublic"                   \
    "-//OASIS//DTD DocBook XML"                             \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
    /etc/xml/catalog                                        &&

xmlcatalog --noout --add "delegateSystem"                   \
    "http://www.oasis-open.org/docbook/"                    \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
    /etc/xml/catalog                                        &&

xmlcatalog --noout --add "delegateURI"                      \
    "http://www.oasis-open.org/docbook/"                    \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/catalog.xml" \
    /etc/xml/catalog

for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
  xmlcatalog --noout --add "public"                                  \
    "-//OASIS//DTD DocBook XML V$DTDVERSION//EN"                     \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
    /usr/share/xml/docbook/xml-dtd-4.5/catalog.xml

  xmlcatalog --noout --add "rewriteSystem"              \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
    /usr/share/xml/docbook/xml-dtd-4.5/catalog.xml

  xmlcatalog --noout --add "rewriteURI"                 \
    "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5"         \
    /usr/share/xml/docbook/xml-dtd-4.5/catalog.xml
done
