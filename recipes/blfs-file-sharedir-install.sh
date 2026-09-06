#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Critical-CVE triage (2026-09-05, /lfs-audit follow-up): XML::Parser-2.48
# (the fix for sa-13.0-020 / CVE-2006-10002 / CVE-2006-10003) bundles Devel::CheckLib
# under its own inc/ but needs File::ShareDir::Install from CPAN at build time --
# `use File::ShareDir::Install; install_share dist => 'share';` in its Makefile.PL.
# Build-time only (not loaded at runtime by XML::Parser itself). Plain ExtUtils::
# MakeMaker module, prereqs are all core Perl (Carp, Exporter, File::Spec, IO::Dir).
# Sourced from CPAN directly (cpan.metacpan.org), sha256 verified against the fetched
# tarball at build time (no separate published digest to cross-check, same trust
# tier as the URL itself -- consistent with this project's checksum-only model).
set -e

perl Makefile.PL
make
make install
