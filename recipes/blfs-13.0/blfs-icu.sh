#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/general/icu.html
# title  : icu-78.2
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: n the application failing if the definition of the data or the behavior of the function
#   ctx: referred by the symbol differs between two versions. To avoid the issue, users will need
#   ctx: to rebuild every package linked to an ICU library as soon as possible once ICU is
#   ctx: updated to a new major version. To determine what external libraries are needed
#   ctx: (directly or indirectly) by an application or a library, run:
#   REVIEWED [drop]: Command Explanations example showing HOW to check a binary's dependency on ICU later ('ldd <application or library>') -- a literal placeholder, not an install step.
# ldd <application or library> 

# --- block 1 --------------------------------------------------
#   ctx: or to see only programs and libraries that directly use a library:
#   REVIEWED [drop]: Same section, readelf variant of the same usage example -- not an install step.
# readelf -d  <application or library> | grep NEEDED

# --- block 2 --------------------------------------------------
#   ctx: cdc837e402ac773f17c7cf8 Download size: 27 MB Estimated disk space required: 408 MB (add
#   ctx: 48 MB for tests) Estimated build time: 0.5 SBU (Using parallelism=4; add 1.9 SBU for
#   ctx: tests) ICU Dependencies Optional Doxygen-1.16.1 (for documentation) Installation of ICU
#   ctx: Note This package expands to the directory icu. A part of a test cannot be run on i686.
#   ctx: Avoid executing it when building for that platform:
case $(uname -m) in
  i?86) sed -e "s/U_PLATFORM_IS_LINUX_BASED/__X86_64__ \&\& &/" \
            -i source/test/intltest/ustrtest.cpp ;;
esac

# --- block 3 --------------------------------------------------
#   ctx: Install ICU by running the following commands:
cd source                 &&
./configure --prefix=/usr &&
make

# --- block 4 --------------------------------------------------
#   ctx: To test the results, issue: make check. One test (intltest) still fails for unknown
#   ctx: reasons on i686 checking some thai conversions. Now, as the root user:
make install

