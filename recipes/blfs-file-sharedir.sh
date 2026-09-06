#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Critical-CVE triage (2026-09-05, /lfs-audit follow-up): XML::Parser-2.48
# (the fix for sa-13.0-020 / CVE-2006-10002 / CVE-2006-10003) needs File::ShareDir at
# runtime -- Expat.pm's own `require File::ShareDir` to locate its installed encoding
# maps under auto/share/dist/XML-Parser. Depends on Class::Inspector (blfs-class-
# inspector.sh, built first). Sourced from CPAN directly (cpan.metacpan.org), sha256
# verified against the fetched tarball at build time (no separate published digest to
# cross-check, same trust tier as the URL itself -- consistent with this project's
# checksum-only model).
set -e

perl Makefile.PL
make
make install
