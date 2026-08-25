#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter05/glibc.html
# title  : 5.5. Glibc-2.43
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: y, searching directories, opening and closing files, reading and writing files, string
#   ctx: handling, pattern matching, arithmetic, and so on. Approximate build time: 1.4 SBU
#   ctx: Required disk space: 890 MB 5.5.1. Installation of Glibc First, create a symbolic link
#   ctx: for LSB compliance. Additionally, for x86_64, create a compatibility symbolic link
#   ctx: required for proper operation of the dynamic library loader:
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

# --- block 1 --------------------------------------------------
#   ctx: Note The above command is correct. The ln command has several syntactic versions, so be
#   ctx: sure to check info coreutils ln and ln(1) before reporting what may appear to be an
#   ctx: error. Some of the Glibc programs use the non-FHS-compliant /var/db directory to store
#   ctx: their runtime data. Apply the following patch to make such programs store their runtime
#   ctx: data in the FHS-compliant locations:
patch -Np1 -i ../glibc-fhs-1.patch

# --- block 2 --------------------------------------------------
#   ctx: The Glibc documentation recommends building Glibc in a dedicated build directory:
mkdir -v build
cd       build

# --- block 3 --------------------------------------------------
#   ctx: Ensure that the ldconfig and sln utilities are installed into /usr/sbin:
echo "rootsbindir=/usr/sbin" > configparms

# --- block 4 --------------------------------------------------
#   ctx: Next, prepare Glibc for compilation:
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib           \
      --enable-kernel=5.4

# --- block 5 --------------------------------------------------
#   ctx: The missing or incompatible msgfmt program is generally harmless. This msgfmt program is
#   ctx: part of the Gettext package, which the host distribution should provide. Note There have
#   ctx: been reports that this package may fail when building as a “parallel make.” If that
#   ctx: occurs, rerun the make command with the -j1 option. Compile the package:
make

# --- block 6 --------------------------------------------------
#   ctx: Install the package: Warning If LFS is not properly set, and despite the
#   ctx: recommendations, you are building as root, the next command will install the newly built
#   ctx: Glibc to your host system, which will almost certainly render it unusable. So
#   ctx: double-check that the environment is correctly set, and that you are not root, before
#   ctx: running the following command.
make DESTDIR=$LFS install

# --- block 7 --------------------------------------------------
#   ctx: n: DESTDIR=$LFS The DESTDIR make variable is used by almost all packages to define the
#   ctx: location where the package should be installed. If it is not set, it defaults to the
#   ctx: root (/) directory. Here we specify that the package is installed in $LFS, which will
#   ctx: become the root directory in Section 7.4, “Entering the Chroot Environment.” Fix a hard
#   ctx: coded path to the executable loader in the ldd script:
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

# --- block 8 --------------------------------------------------
#   ctx: Now that our cross toolchain is in place, it is important to ensure that compiling and
#   ctx: linking will work as expected. We do this by performing some sanity checks:
echo 'int main(){}' | $LFS_TGT-gcc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# --- block 9 --------------------------------------------------
#   ctx: Note that this path should not contain /mnt/lfs (or the value of the LFS variable if you
#   ctx: used a different one). The path is resolved when the compiled program is executed, and
#   ctx: that should only happen after we enter the chroot environment where the kernel would
#   ctx: consider $LFS as the root directory (/). Now make sure that we're set up to use the
#   ctx: correct start files:
grep -E -o "$LFS/lib.*/S?crt[1in].*succeeded" dummy.log

# --- block 10 --------------------------------------------------
#   ctx: Verify that the compiler is searching for the correct header files:
grep -B3 "^ $LFS/usr/include" dummy.log

# --- block 11 --------------------------------------------------
#   ctx: Again, the directory named after your target triplet may be different than the above,
#   ctx: depending on your system architecture. Next, verify that the new linker is being used
#   ctx: with the correct search paths:
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# --- block 12 --------------------------------------------------
#   ctx: A 32-bit system may use a few other directories, but anyway the important facet here is
#   ctx: all the paths should begin with an equal sign (=), which would be replaced with the
#   ctx: sysroot directory that we've configured for the linker. Next make sure that we're using
#   ctx: the correct libc:
grep "/lib.*/libc.so.6 " dummy.log

# --- block 13 --------------------------------------------------
#   ctx: Make sure GCC is using the correct dynamic linker:
grep found dummy.log

# --- block 14 --------------------------------------------------
#   ctx: If the output does not appear as shown above or is not received at all, then something
#   ctx: is seriously wrong. Investigate and retrace the steps to find out where the problem is
#   ctx: and correct it. Any issues should be resolved before continuing with the process. Once
#   ctx: everything is working correctly, clean up the test files:
rm -v a.out dummy.log

