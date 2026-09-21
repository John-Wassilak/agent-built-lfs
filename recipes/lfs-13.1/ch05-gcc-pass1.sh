#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter05/gcc-pass1.html
# title  : 5.3 GCC-16.2.0 - Pass 1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ies so the GCC build procedures will automatically use them: Note There are frequent
#   ctx: misunderstandings about the instructions here. The procedures are the same as every
#   ctx: other package, as explained earlier (Package build instructions). First, extract the
#   ctx: gcc-16.2.0 tarball from the sources directory, and then change to the directory created.
#   ctx: Only then should you proceed with the instructions below.
tar -xf ../mpfr-4.2.2.tar.xz
mv -v mpfr-4.2.2 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.4.1.tar.xz
mv -v mpc-1.4.1 mpc

# --- block 1 --------------------------------------------------
#   ctx: On x86_64 hosts, set the default directory name for 64-bit libraries to “lib”:
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

# --- block 2 --------------------------------------------------
#   ctx: u may run diff -u gcc/config/i386/t-linux64{.orig,} to visualize the change done by the
#   ctx: sed command afterwards. We'll simply use -i (which just edits the original file inplace
#   ctx: without copying it) for all other packages in the book, but you can change it to -i.orig
#   ctx: in any case you want to keep a copy of the original file. The GCC documentation
#   ctx: recommends building GCC in a dedicated build directory:
mkdir -v build
cd       build

# --- block 3 --------------------------------------------------
#   ctx: Prepare GCC for compilation:
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.44 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-fixincludes     \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

# --- block 4 --------------------------------------------------
#   ctx: or threading, libatomic, libgomp, libquadmath, libssp, libvtv, and the C++ standard
#   ctx: library respectively. These features may fail to compile when building a cross-compiler
#   ctx: and are not necessary for the task of cross-compiling the temporary libc.
#   ctx: --enable-languages=c,c++ This option ensures that only the C and C++ compilers are
#   ctx: built. These are the only languages needed now. Compile GCC by running:
make

# --- block 5 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 6 --------------------------------------------------
#   ctx: imits.h does not exist, so the internal header that has just been installed is a
#   ctx: partial, self-contained file and does not include the extended features of the system
#   ctx: header. This is adequate for building Glibc, but the full internal header will be needed
#   ctx: later. Create a full version of the internal header using a command that is identical to
#   ctx: what the GCC build system does in normal circumstances:
cat ../gcc/{limitx,glimits,limity}.h  > \
  $($LFS_TGT-gcc -print-file-name=include)/limits.h

