#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for swtpm.
# source: github.com/stefanberger/swtpm, tag v0.10.2 (released 2026-08-19), GitHub
# archive tarball. Arch carries it in [extra]; its PKGBUILD was used only to cross-check
# the configure line.
#
# rationale: the software TPM that QEMU talks to over a unix socket (-tpmdev emulator),
# built on libtpms (previous step). Windows 11 requires TPM 2.0. Added 2026-10-21 for
# server's Windows guest (packages.py seq 272).
#
# Build deps, all present before this step: libtpms (>= 0.10, from pkg-config),
# json-glib (BLFS), libtasn1 and GnuTLS (swtpm_cert, and certtool for swtpm-localca),
# libseccomp, OpenSSL. autogen.sh runs configure for the same reason as libtpms's.
#
# --with-gnutls: needed for swtpm_cert, which writes the EK and platform certificates
# that swtpm_setup --create-ek-cert asks for. --with-seccomp: swtpm sandboxes itself
# when libseccomp is there. --without-selinux: no SELinux on this system.
# --without-cuse: the CUSE character-device interface is only for guests that need a
# /dev/vtpm* node; QEMU uses the socket interface. --disable-tests: the test suite needs
# expect, socat and python3-twisted, none of which are built here.
#
# Configuration: install drops /etc/swtpm_setup.conf, /etc/swtpm-localca.conf and
# .options, and creates /var/lib/swtpm-localca (chowned to the "tss" user if it exists;
# the Makefile's chown is `|| true`, and there is no tss user here). That root-owned CA
# is for root-run VMs. A VM run by an ordinary user creates its own per-user config with
# `swtpm_setup --create-config-files skip-if-exist`, which puts the CA under
# ~/.config/var/lib/swtpm-localca -- the launcher does that, so nothing here needs root
# setup beyond install.
set -e

./autogen.sh --prefix=/usr        \
             --sysconfdir=/etc    \
             --localstatedir=/var \
             --with-openssl       \
             --with-gnutls        \
             --with-seccomp       \
             --without-selinux    \
             --without-cuse       \
             --disable-tests      \
             --disable-static
make

make install
