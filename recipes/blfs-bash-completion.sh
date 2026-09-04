#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS 13.0-systemd book page covers this package.
# source: github.com/scop/bash-completion, release tag 2.18.0 (upstream release
# tarball, ships a generated ./configure -- confirmed by inspection, no autoreconf
# needed). Checked the book directly first (grepped every book/blfs-13.0/*.html for
# "bash-completion"): it only appears as an optional install-dir a handful of other
# packages (systemd, colord, ModemManager, GNOME pieces, rust) drop their own
# completions into if present. BLFS has no page for the framework package itself.
#
# rationale: operator noticed `pass`/`pass-otp` tab-completion, which worked on a
# prior (non-LFS) system, doesn't work here. Root cause, confirmed by inspection:
# both packages already install their completion scripts correctly
# (/usr/share/bash-completion/completions/pass, /etc/bash_completion.d/pass-otp --
# see hosts/*/manifests/blfs-pass*.txt) but nothing on this system ever sources
# them -- this framework package (the thing that finds and loads on-demand
# completions) was simply never built. No checksum published by upstream release
# assets (checked: GitHub release has only the tarball, no sha256sums file) --
# same class of gap already noted for grim/enchant; recorded as this session's own
# sha256 of the fetched release tarball.
set -e

./configure --prefix=/usr --sysconfdir=/etc
make
make install

# Book-derived /etc/bashrc (recipes/blfs-shell-startup-files.sh) is a `cat >`
# heredoc, already run on this host -- appending here instead of touching that
# generated file (CLAUDE.md: don't edit generated recipes in place). Upstream's
# own README documents exactly this fallback for systems where /etc/profile.d
# isn't sourced by non-login interactive shells (true here: this project's
# /etc/profile only runs profile.d scripts for login shells, and /etc/bashrc is
# what actual interactive terminals source). The profile.d script itself
# self-guards (checks $PS1, bash version, and $BASH_COMPLETION_VERSINFO to avoid
# double-sourcing), so this append is safe however bash was invoked.
cat >> /etc/bashrc << "EOF"

# bash-completion (hand-authored, not a BLFS book page). /etc/profile.d is only
# sourced for login shells on this system; most interactive shells need this.
if [ -r /etc/profile.d/bash_completion.sh ]; then
    . /etc/profile.d/bash_completion.sh
fi
EOF

echo "### version"
/usr/share/bash-completion/bash_completion --version 2>&1 | head -1 || true
