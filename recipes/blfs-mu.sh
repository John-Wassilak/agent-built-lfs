#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS 13.0-systemd book page covers mu (or mu4e; mu4e's
# elisp has shipped inside mu's own source tree since mu 1.4, there is no separate
# mu4e tarball upstream).
# source: github.com/djcb/mu, release tag v1.14.3 -- official release, upstream
# publishes a real sha256sum file for it (mu-1.14.3.tar.xz.sha256sum), unlike most
# hand-authored packages in this project.
# rationale: operator-requested mu4e. Real deps checked directly against meson.build:
# glib-2.0/gio-2.0 >= 2.80 (have, 2.86.4), gmime-3.0 >= 3.2.13 (blfs-gmime3, this
# session), xapian-core >= 1.4.22 (blfs-xapian, this session). fmt and CLI11 are
# optional with a vendored fallback under thirdparty/ (mu falls back cleanly if not
# found -- CLI11 happens to already be present, seq from the quickshell/DMS chain,
# so mu will link the system copy rather than its own vendored one). guile/scm
# default to meson feature 'auto' and degrade quietly -- guile is not built here.
# mu4e's own lispdir defaults (meson.build: datadir/emacs/site-lisp/mu4e) resolve to
# exactly /usr/share/emacs/site-lisp/mu4e with --prefix=/usr, matching
# ~/Config/common/emacs.d/email.el's hardcoded load-path with no override needed.
# bash-completion's meson option is 'auto' too -- now that this project's own
# bash-completion framework exists (this session, seq 246/253), mu's own completions
# install and get picked up automatically.
set -e

mkdir build &&
cd    build &&

meson setup --prefix=/usr       \
            --buildtype=release \
            -D tests=disabled   \
            ..                  &&
ninja

ninja install

echo "### version"
/usr/bin/mu --version 2>&1 | head -1 || true
