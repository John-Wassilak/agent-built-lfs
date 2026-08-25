#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/p11-kit.html
# title  : p11-kit-0.26.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: .2.tar.xz Download MD5 sum: 99edde5f38697ed2d47c55544347be4e Download size: 1.0 MB
#   ctx: Estimated disk space required: 110 MB (with tests) Estimated build time: 0.5 SBU (with
#   ctx: tests) p11-kit Dependencies Recommended libtasn1-4.21.0 Recommended (runtime)
#   ctx: make-ca-1.16.1 Optional GTK-Doc-1.35.1, libxslt-1.1.45, and nss-3.120.1 (runtime)
#   ctx: Installation of p11-kit Prepare the distribution specific anchor hook:
sed '20,$ d' -i trust/trust-extract-compat &&

cat >> trust/trust-extract-compat << "EOF"
# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Update trust stores
/usr/sbin/make-ca -r
EOF

# --- block 1 --------------------------------------------------
#   ctx: Install p11-kit by running the following commands:
mkdir p11-build &&
cd    p11-build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D trust_paths=/etc/pki/anchors &&
ninja

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue: ninja test. Now, as the root user:
ninja install &&
ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
        /usr/bin/update-ca-certificates

# --- block 3 --------------------------------------------------
#   ctx: .45 and wish to rebuild the documentation and generate manual pages. Configuring p11-kit
#   ctx: The p11-kit trust module (/usr/lib/pkcs11/p11-kit-trust.so) can be used as a drop-in
#   ctx: replacement for /usr/lib/libnssckbi.so to transparently make the system CAs available to
#   ctx: NSS aware applications, rather than the static list provided by /usr/lib/libnssckbi.so.
#   ctx: As the root user, execute the following commands:
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

