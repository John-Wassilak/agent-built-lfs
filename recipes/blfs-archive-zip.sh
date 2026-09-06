#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page of its own; listed as a Required build
# dependency on xsoft/libreoffice.html (Archive-Zip-1.68) and cataloged, with dozens of
# other standalone CPAN modules sharing this exact install pattern, on BLFS's own
# general/perl-modules.html. Plain ExtUtils::MakeMaker module, no further prereqs beyond
# core Perl -- same "hand-authored, no further prereqs" pattern as seq 291-293
# (Class::Inspector, File::ShareDir, File::ShareDir::Install). Sourced from CPAN
# directly (cpan.metacpan.org), sha256 verified against the fetched tarball at build
# time (no separate published digest to cross-check, same trust tier as the URL itself).
set -e

perl Makefile.PL
make
make install
