#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.1-systemd book.
# source : book/13.1/chapter08/perl.html
# title  : 8.46 Perl-5.44.0
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: rl package contains the Practical Extraction and Report Language. Approximate build
#   ctx: time: 1.3 SBU Required disk space: 261 MB 8.46.1 Installation of Perl This version of
#   ctx: Perl builds the Compress::Raw::Zlib and Compress::Raw::BZip2 modules. By default Perl
#   ctx: will use an internal copy of the sources for the build. Issue the following command so
#   ctx: that Perl will use the libraries installed on the system:
export BUILD_ZLIB=False
export BUILD_BZIP2=0

# --- block 1 --------------------------------------------------
#   ctx: To have full control over the way Perl is set up, you can remove the “-des” options from
#   ctx: the following command and hand-pick the way this package is built. Alternatively, use
#   ctx: the command exactly as shown below to use the defaults that Perl auto-detects:
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.44/core_perl      \
             -D archlib=/usr/lib/perl5/5.44/core_perl      \
             -D sitelib=/usr/lib/perl5/5.44/site_perl      \
             -D sitearch=/usr/lib/perl5/5.44/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.44/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.44/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads

# --- block 2 --------------------------------------------------
#   ctx: The meaning of the new Configure options: -D pager="/usr/bin/less -isR" This ensures
#   ctx: that less is used instead of more. -D man1dir=/usr/share/man/man1 -D
#   ctx: man3dir=/usr/share/man/man3 Since Groff is not installed yet, Configure will not create
#   ctx: man pages for Perl. These parameters override this behavior. -D usethreads Build Perl
#   ctx: with support for threads. Compile the package:
make

# --- block 3 --------------------------------------------------
#   ctx: To test the results, issue:
#   REVIEWED [drop]: TEST_JOBS=$(nproc) make test_harness hangs indefinitely, not just slowly. First confirmed 2026-08-30 (laptop) at ~17.5 hours stuck, ps showing three of Perl's own network tests still running (t/nntp_ipv6.t, t/pop3_ipv6.t, t/smtp_ipv6.t) plus a <defunct> zombie child never reaped. These open real IPv6 sockets; at this point in the book the chroot has no configured network stack at all (that's a BLFS-era concern), so connect() calls that would fail fast on a normal system instead sit forever with no local timeout. Promoted here 2026-09-08 after a second host (server-rebuild, fresh LFS 13.1 chroot build) reproduced the identical hang -- confirming this is a book-general issue, not one host's timing/environment, per the note this entry carried when it was laptop-only. Dropping the whole test_harness run rather than excluding just the three files: Perl's own test harness has no book-documented flag for excluding individual .t files short of deleting them from the source tree by hand, and this project already treats most Chapter 8 test suites as optional rather than a correctness gate.
# TEST_JOBS=$(nproc) make test_harness

# --- block 4 --------------------------------------------------
#   ctx: Install the package and clean up:
make install
unset BUILD_ZLIB BUILD_BZIP2

