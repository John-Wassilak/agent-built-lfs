#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS 13.0-systemd book page covers isync (mbsync).
# source: sourceforge.net/projects/isync (the project's own canonical distribution
# point -- checked, no GitHub/GitLab release tarballs published, only source repo
# mirrors), release 1.5.1. md5 verified against SourceForge's own file API.
# rationale: operator-requested mu4e; ~/Config/common/emacs.d/email.el sets
# mu4e-get-mail-command to "mbsync -a", and ~/Config/common/isync/mbsyncrc already
# configures all 5 accounts. Plain autotools, real deps checked via `configure
# --help`: --with-ssl/--with-sasl/--with-zlib are all auto-detect, not required --
# OpenSSL and GnuTLS are both already built (either satisfies TLS), this project's
# mbsyncrc uses plain IMAPS auth (no XOAUTH2/Kerberos), so cyrus-sasl (not built) is
# never needed.
set -e

./configure --prefix=/usr &&
make

make install

echo "### version"
/usr/bin/mbsync -V 2>&1 | head -1 || true
