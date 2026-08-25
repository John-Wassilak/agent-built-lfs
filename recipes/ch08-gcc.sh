#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/gcc.html
# title  : 8.30. GCC-15.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The GCC package contains the GNU compiler collection, which includes the C and C++
#   ctx: compilers. Approximate build time: 45 SBU (with tests) Required disk space: 6.6 GB
#   ctx: 8.30.1. Installation of GCC First, make a fix required by glibc-2.43 and later:
sed -i 's/char [*]q/const &/' libgomp/affinity-fmt.c

# --- block 1 --------------------------------------------------
#   ctx: If building on x86_64, change the default directory name for 64-bit libraries to “lib”:
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# --- block 2 --------------------------------------------------
#   ctx: The GCC documentation recommends building GCC in a dedicated build directory:
mkdir -v build
cd       build

# --- block 3 --------------------------------------------------
#   ctx: Prepare GCC for compilation:
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

# --- block 4 --------------------------------------------------
#   ctx: ased on fixed addresses of sensitive code or data in the executables. SSP (Stack
#   ctx: Smashing Protection) is a technique to ensure that the parameter stack is not corrupted.
#   ctx: Stack corruption can, for example, alter the return address of a subroutine, thus
#   ctx: transferring control to some dangerous code (existing in the program or shared
#   ctx: libraries, or injected by the attacker somehow). Compile the package:
make

# --- block 5 --------------------------------------------------
#   ctx: st distros with a tight stack limit, explicitly set the stack size hard limit to
#   ctx: infinite. On most host distros (and the final LFS system) the hard limit is infinite by
#   ctx: default, but there is no harm done by setting it explicitly. It's not necessary to
#   ctx: change the stack size soft limit because GCC will automatically set it to an appropriate
#   ctx: value, as long as the value does not exceed the hard limit:
ulimit -s -H unlimited

# --- block 6 --------------------------------------------------
#   ctx: Now remove several known test failures:
sed -e '/cpython/d' -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp

# --- block 7 --------------------------------------------------
#   ctx: Test the results as a non-privileged user, but do not stop at errors:
set +e
chown -R tester .
su tester -c "PATH=$PATH make -k check"
__rc=$?
set -e
echo "### TESTSUITE ch08-gcc block 7 exit=$__rc (non-fatal, compare against book)"

# --- block 8 --------------------------------------------------
#   ctx: To extract a summary of the test suite results, run:
../contrib/test_summary

# --- block 9 --------------------------------------------------
#   ctx: ibstdc++, 17_intro/badnames.cc, 17_intro/names.cc, 17_intro/names_fortify.cc, and
#   ctx: experimental/names.cc, are known to fail due to changes with glibc-2.43. A few
#   ctx: unexpected failures cannot always be avoided. In some cases test failures depend on the
#   ctx: specific hardware of the system. Unless the test results are vastly different from those
#   ctx: at the above URL, it is safe to continue. Install the package:
make install

# --- block 10 --------------------------------------------------
#   ctx: The GCC build directory is owned by tester now, and the ownership of the installed
#   ctx: header directory (and its content) is incorrect. Change the ownership to the root user
#   ctx: and group:
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/15.2.0/include{,-fixed}

# --- block 11 --------------------------------------------------
#   ctx: Create a symlink required by the FHS for "historical" reasons.
ln -svr /usr/bin/cpp /usr/lib

# --- block 12 --------------------------------------------------
#   ctx: Many packages use the name cc to call the C compiler. We've already created cc as a
#   ctx: symlink in gcc-pass2, create its man page as a symlink as well:
ln -sv gcc.1 /usr/share/man/man1/cc.1

# --- block 13 --------------------------------------------------
#   ctx: Add a compatibility symlink to enable building programs with Link Time Optimization
#   ctx: (LTO):
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/15.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

# --- block 14 --------------------------------------------------
#   ctx: Now that our final toolchain is in place, it is important to again ensure that compiling
#   ctx: and linking will work as expected. We do this by performing some sanity checks:
echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# --- block 15 --------------------------------------------------
#   ctx: Now make sure that we're set up to use the correct start files:
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log

# --- block 16 --------------------------------------------------
#   ctx: Depending on your machine architecture, the above may differ slightly. The difference
#   ctx: will be the name of the directory after /usr/lib/gcc. The important thing to look for
#   ctx: here is that gcc has found all three crt*.o files under the /usr/lib directory. Verify
#   ctx: that the compiler is searching for the correct header files:
grep -B4 '^ /usr/include' dummy.log

# --- block 17 --------------------------------------------------
#   ctx: Again, the directory named after your target triplet may be different than the above,
#   ctx: depending on your system architecture. Next, verify that the new linker is being used
#   ctx: with the correct search paths:
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# --- block 18 --------------------------------------------------
#   ctx: Next make sure that we're using the correct libc:
grep "/lib.*/libc.so.6 " dummy.log

# --- block 19 --------------------------------------------------
#   ctx: Make sure GCC is using the correct dynamic linker:
grep found dummy.log

# --- block 20 --------------------------------------------------
#   ctx: If the output does not appear as shown above or is not received at all, then something
#   ctx: is seriously wrong. Investigate and retrace the steps to find out where the problem is
#   ctx: and correct it. Any issues should be resolved before continuing with the process. Once
#   ctx: everything is working correctly, clean up the test files:
rm -v a.out dummy.log

# --- block 21 --------------------------------------------------
#   ctx: Finally, move a misplaced file:
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

