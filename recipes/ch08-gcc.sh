#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/gcc.html
# title  : 8.32 GCC-16.2.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: The GCC package contains the GNU compiler collection, which includes the C and C++
#   ctx: compilers. Approximate build time: 53 SBU (with tests) Required disk space: 7.3 GB
#   ctx: 8.32.1 Installation of GCC If building on x86_64, change the default directory name for
#   ctx: 64-bit libraries to “lib”:
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

# --- block 1 --------------------------------------------------
#   ctx: The GCC documentation recommends building GCC in a dedicated build directory:
mkdir -v build
cd       build

# --- block 2 --------------------------------------------------
#   ctx: Prepare GCC for compilation:
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --enable-targets=all     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

# --- block 3 --------------------------------------------------
#   ctx: ased on fixed addresses of sensitive code or data in the executables. SSP (Stack
#   ctx: Smashing Protection) is a technique to ensure that the parameter stack is not corrupted.
#   ctx: Stack corruption can, for example, alter the return address of a subroutine, thus
#   ctx: transferring control to some dangerous code (existing in the program or shared
#   ctx: libraries, or injected by the attacker somehow). Compile the package:
make

# --- block 4 --------------------------------------------------
#   ctx: st distros with a tight stack limit, explicitly set the stack size hard limit to
#   ctx: infinite. On most host distros (and the final LFS system) the hard limit is infinite by
#   ctx: default, but there is no harm done by setting it explicitly. It's not necessary to
#   ctx: change the stack size soft limit because GCC will automatically set it to an appropriate
#   ctx: value, as long as the value does not exceed the hard limit:
ulimit -s -H unlimited

# --- block 5 --------------------------------------------------
#   ctx: Test the results as a non-privileged user, but do not stop at errors:
set +e
chown -R tester .
su tester -c "PATH=$PATH make -k check"
__rc=$?
set -e
echo "### TESTSUITE ch08-gcc block 5 exit=$__rc (non-fatal, compare against book)"

# --- block 6 --------------------------------------------------
#   ctx: To extract a summary of the test suite results, run:
../contrib/test_summary -t

# --- block 7 --------------------------------------------------
#   ctx: confirmed none indicates a critical issue. Most of them are because the test case
#   ctx: author did not anticipate --enable-default-ssp or --enable-default-pie. A few unexpected
#   ctx: failures cannot always be avoided. In some cases test failures depend on the specific
#   ctx: hardware of the system. Unless the test results are vastly different from those at the
#   ctx: above URL, it is safe to continue. Install the package:
make install

# --- block 8 --------------------------------------------------
#   ctx: The GCC build directory is owned by tester now, and the ownership of the installed
#   ctx: header directory (and its content) is incorrect. Change the ownership to the root user
#   ctx: and group:
chown -v -R root:root $(gcc -print-file-name=include){,-fixed}

# --- block 9 --------------------------------------------------
#   ctx: Create a symlink required by the FHS for "historical" reasons.
ln -svr /usr/bin/cpp /usr/lib

# --- block 10 --------------------------------------------------
#   ctx: Many packages use the name cc to call the C compiler. We've already created cc as a
#   ctx: symlink in gcc-pass2, create its man page as a symlink as well:
ln -sv gcc.1 /usr/share/man/man1/cc.1

# --- block 11 --------------------------------------------------
#   ctx: Add a compatibility symlink to enable building programs with Link Time Optimization
#   ctx: (LTO):
ln -sfvr $(gcc -print-prog-name=liblto_plugin.so) /usr/lib/bfd-plugins/

# --- block 12 --------------------------------------------------
#   ctx: Now that our final toolchain is in place, it is important to again ensure that compiling
#   ctx: and linking will work as expected. We do this by performing some sanity checks:
echo 'int main(){}' | cc -x c - -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

# --- block 13 --------------------------------------------------
#   ctx: Now make sure that we're set up to use the correct start files:
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log

# --- block 14 --------------------------------------------------
#   ctx: Depending on your machine architecture, the above may differ slightly. The difference
#   ctx: will be the name of the directory after /usr/lib/gcc. The important thing to look for
#   ctx: here is that gcc has found all three crt*.o files under the /usr/lib directory. Verify
#   ctx: that the compiler is searching for the correct header files:
grep -B4 '^ /usr/include' dummy.log

# --- block 15 --------------------------------------------------
#   ctx: Again, the directory named after your target triplet may be different than the above,
#   ctx: depending on your system architecture. Next, verify that the new linker is being used
#   ctx: with the correct search paths:
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'

# --- block 16 --------------------------------------------------
#   ctx: Next make sure that we're using the correct libc:
grep "/lib.*/libc.so.6 " dummy.log

# --- block 17 --------------------------------------------------
#   ctx: Make sure GCC is using the correct dynamic linker:
grep found dummy.log

# --- block 18 --------------------------------------------------
#   ctx: If the output does not appear as shown above or is not received at all, then something
#   ctx: is seriously wrong. Investigate and retrace the steps to find out where the problem is
#   ctx: and correct it. Any issues should be resolved before continuing with the process. Once
#   ctx: everything is working correctly, clean up the test files:
rm -v a.out dummy.log

# --- block 19 --------------------------------------------------
#   ctx: Finally, move a misplaced file:
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

