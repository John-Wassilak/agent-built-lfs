#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Critical-CVE triage (2026-09-05, /lfs-audit follow-up): File::ShareDir
# (needed by XML::Parser-2.48, see blfs-file-sharedir.sh) requires Class::Inspector.
# Plain ExtUtils::MakeMaker module, no further prereqs beyond core Perl. Sourced from
# CPAN directly (cpan.metacpan.org), sha256 verified against the fetched tarball at
# build time (no separate published digest to cross-check, same trust tier as the
# URL itself -- consistent with this project's checksum-only model).
set -e

perl Makefile.PL
make
make install
