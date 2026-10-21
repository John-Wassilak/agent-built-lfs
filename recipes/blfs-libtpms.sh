#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for libtpms.
# source: github.com/stefanberger/libtpms, tag v0.10.2 (released 2026-01-02), GitHub
# archive tarball. Arch carries it in [extra]; its PKGBUILD was used only to cross-check
# the configure line.
#
# rationale: the TPM 1.2/2.0 emulation library behind swtpm (next step), which gives a
# QEMU guest a virtual TPM. Windows 11 refuses to install without TPM 2.0. Added
# 2026-10-21 for server's Windows guest (packages.py seq 271).
#
# A GitHub archive has no generated configure, so autogen.sh runs first; autoconf,
# automake, libtool and pkg-config are all LFS chapter 8. autogen.sh also runs
# configure, so the options go to it directly.
#
# --with-openssl: the crypto backend (OpenSSL is LFS chapter 8). --with-tpm2: TPM 2.0
# support, the whole reason for the package; TPM 1.2 is built by default alongside it
# and costs nothing. --disable-static: nothing here links it statically.
#
# The sed is upstream commit fc8820cfaa ("Fix a compilation error in
# TPMLIB_GetPlaintext", master 2026-01-02, not in v0.10.2). glibc 2.43+ returns a
# const pointer from strstr() on a const haystack, and the package builds with
# -Werror, so v0.10.2 fails with -Werror=discarded-qualifiers on GCC 16 / glibc
# 2.44 (seen on server, 2026-10-21). Drop it when a release carries the fix.
set -e

sed -i 's/^    char \*start, \*end;$/    const char *start, *end;/' src/tpm_library.c
grep -q '^    const char \*start, \*end;' src/tpm_library.c

./autogen.sh --prefix=/usr     \
             --with-openssl    \
             --with-tpm2       \
             --disable-static
make

make install
