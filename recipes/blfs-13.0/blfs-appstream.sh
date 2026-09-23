#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/appstream.html
# title  : AppStream-1.1.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ed: 40 MB Estimated build time: less than 0.1 SBU (add 0.1 SBU for tests; both using
#   ctx: parallelism=4) AppStream Dependencies Required cURL-8.18.0, itstool-2.0.7,
#   ctx: libfyaml-0.9.4, libxml2-2.15.1, libxmlb-0.3.25, and libxslt-1.1.45 Recommended
#   ctx: docbook-xsl-nons-1.79.2 Optional Gi-DocGen-2026.1, Qt-6.10.2, DAPS, and libstemmer
#   ctx: Installation of AppStream Install AppStream by running the following commands:
mkdir build &&
cd    build &&

meson setup --prefix=/usr            \
            --buildtype=release      \
            -D apidocs=false         \
            -D bash-completion=false \
            -D stemming=false   .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install &&
mv -v /usr/share/doc/appstream{,-1.1.2}

# --- block 2 --------------------------------------------------
#   ctx: pplications into this package. -D man=false: This switch disables building the manpages.
#   ctx: Add it if you do not have docbook-xsl-nons-1.79.2 installed. Configuring AppStream
#   ctx: Config Files /usr/share/metainfo/org.linuxfromscratch.lfs.xml Configuration Information
#   ctx: AppStream expects an operating system metainfo file describing the GNU/Linux
#   ctx: distribution. As the root user, create the file describing LFS:
install -vdm755 /usr/share/metainfo &&
cat > /usr/share/metainfo/org.linuxfromscratch.lfs.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="operating-system">
  <id>org.linuxfromscratch.lfs</id>
  <name>Linux From Scratch</name>
  <summary>A customized Linux system built entirely from source</summary>
  <description>
    <p>
      Linux From Scratch (LFS) is a project that provides you with
      step-by-step instructions for building your own customized Linux
      system entirely from source.
    </p>
  </description>
  <url type="homepage">https://www.linuxfromscratch.org/lfs/</url>
  <metadata_license>MIT</metadata_license>
  <developer id='linuxfromscratch.org'>
    <name>The Linux From Scratch Editors</name>
  </developer>

  <releases>
    <release version="13.0" type="stable" date="2026-03-05">
      <description>
        <p>Now contains Binutils 2.46.0, GCC-15.2.0, Glibc-2.43,
        Linux kernel 6.18, and six security updates.</p>
      </description>
    </release>

    <release version="12.4" type="stable" date="2025-09-01">
      <description>
        <p>Now contains Binutils 2.45, GCC-15.2.0, Glibc-2.42,
        Linux kernel 6.16, and twelve security updates.</p>
      </description>
    </release>

    <release version="12.3" type="stable" date="2025-03-05">
      <description>
        <p>Now contains Binutils 2.44, GCC-14.2.0, Glibc-2.41, and
        Linux Kernel 6.13, and three security updates.</p>
      </description>
    </release>
  </releases>
</component>
EOF

