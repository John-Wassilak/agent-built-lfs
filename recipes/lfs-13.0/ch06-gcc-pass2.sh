#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter06/gcc-pass2.html
# title  : 6.18. GCC-15.2.0 - Pass 2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The GCC package contains the GNU compiler collection, which includes the C and C++
#   ctx: compilers. Approximate build time: 4.5 SBU Required disk space: 6.0 GB 6.18.1.
#   ctx: Installation of GCC As in the first build of GCC, the GMP, MPFR, and MPC packages are
#   ctx: required. Unpack the tarballs and move them into the required directories:
tar -xf ../mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

# --- block 1 --------------------------------------------------
#   ctx: If you are building on x86_64, change the default directory name for 64-bit libraries to
#   ctx: “lib”:
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# --- block 2 --------------------------------------------------
#   ctx: Override the build rules of the libgcc and libstdc++ headers to allow building these
#   ctx: libraries with POSIX threads support:
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

# --- block 3 --------------------------------------------------
#   ctx: Create a separate build directory again:
mkdir -v build
cd       build

# --- block 4 --------------------------------------------------
#   ctx: Before starting to build GCC, remember to unset any environment variables that override
#   ctx: the default optimization flags. Now prepare GCC for compilation:
../configure                   \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --target=$LFS_TGT          \
    --prefix=/usr              \
    --with-build-sysroot=$LFS  \
    --enable-default-pie       \
    --enable-default-ssp       \
    --disable-nls              \
    --disable-multilib         \
    --disable-libatomic        \
    --disable-libgomp          \
    --disable-libquadmath      \
    --disable-libsanitizer     \
    --disable-libssp           \
    --disable-libvtv           \
    --enable-languages=c,c++   \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc

# --- block 5 --------------------------------------------------
#   ctx: in this pass, instead of the previous version built in gcc-pass1. The previous version
#   ctx: cannot properly support C++ exception handling because it was built without libc
#   ctx: support. --disable-libsanitizer Disable GCC sanitizer runtime libraries. They are not
#   ctx: needed for the temporary installation. In gcc-pass1 it was implied by
#   ctx: --disable-libstdcxx, and now we can explicitly pass it. Compile the package:
make

# --- block 6 --------------------------------------------------
#   ctx: Install the package:
make DESTDIR=$LFS install

# --- block 7 --------------------------------------------------
#   ctx: As a finishing touch, create a utility symlink. Many programs and scripts run cc instead
#   ctx: of gcc, which is used to keep programs generic and therefore usable on all kinds of UNIX
#   ctx: systems where the GNU C compiler is not always installed. Running cc leaves the system
#   ctx: administrator free to decide which C compiler to install:
ln -sv gcc $LFS/usr/bin/cc

