#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libp11. The book's only libp11 mention
# is the string "libp11-kit.so" on postlfs/p11-kit.html, which is a different library
# from a different project (`find book/blfs-13.0 -iname '*libp11*'` returns nothing).
#
# source: github.com/OpenSC/libp11, release libp11-0.4.21 (2026-09-07) -- the project's
# own release assets, not a tag archive.
#
# provenance: sha256 efdb523aef8613d447e6a2d38227d4b389866f4bcf4b503130acd7f759490847,
# and the detached signature libp11-0.4.21.tar.gz.asc published beside it verifies GOOD
# against RSA key 2BC7E4E67E3CC0C1BEA72F8C2EFC7FF0D416E014, uid "Michał Trojnara
# <Michal.Trojnara@stunnel.org>" -- libp11's maintainer. The key was fetched from
# keys.openpgp.org by fingerprint, i.e. from a different origin than the tarball, so
# unlike the same-origin md5 checks the Qt submodules get, this is a real independent
# trust path.
#
# rationale: a hard dependency of nextcloud-desktop (seq 333), and an easy one to miss,
# because it does not appear in any Qt or KDE dependency list. Its top-level
# CMakeLists.txt has, unconditionally inside `if(BUILD_CLIENT)`:
#
#     pkg_check_modules(OPENSC-LIBP11 libp11 REQUIRED IMPORTED_TARGET)
#
# and src/libsync links PkgConfig::OPENSC-LIBP11 into libnextcloudsync. It is what backs
# the client's option to keep the end-to-end-encryption key on a hardware PKCS#11 token
# rather than in the keychain. REQUIRED means cmake stops at configure time without it,
# whether or not anyone owns such a token.
#
# Three libraries come out of this build, and only the first is what nextcloud needs:
#   libp11        the higher-level wrapper over a PKCS#11 module, plus libp11.pc, which
#                 is what the pkg_check_modules line above looks for.
#   pkcs11prov    an OpenSSL 3.x provider, installed into openssl's own modules dir.
#   pkcs11        the legacy OpenSSL engine, installed into openssl's engines dir.
# The two plugins are inert unless openssl.cnf loads them, which nothing here does, and
# there is no configure switch that builds the library without them.
#
# Portable: names no device, no display, no GPU, no disk. Shared per CLAUDE.md's
# shared/host test. No PKCS#11 module (opensc, softhsm) is built here and none is
# needed -- libp11 dlopens whichever module a user configures at run time, so this step
# adds a capability rather than a dependency.
set -e

# Plain autotools. The two plugin install directories are left to configure's own
# defaults, which it reads from openssl's pkg-config rather than guessing: verified live
# before writing this, `pkg-config --variable=enginesdir libcrypto` is /usr/lib/engines-3
# and `--variable=modulesdir libcrypto` is /usr/lib/ossl-modules, both of which exist
# already. Passing them explicitly would only be needed on a system whose openssl does
# not publish those variables.
#
# --disable-static: nothing here links libp11 statically, and the .a would otherwise be
# installed and show up in this step's manifest as a file no package ever opens.
./configure --prefix=/usr \
            --disable-static &&
make

make install

echo "### version"
pkg-config --modversion libp11
echo "### installed plugins"
ls -1 /usr/lib/ossl-modules/pkcs11prov.so /usr/lib/engines-3/pkcs11.so 2>/dev/null || true
