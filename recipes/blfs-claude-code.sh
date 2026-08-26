#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Installs Claude Code from npm, per-user under john's own home
# directory rather than npm's system-wide default prefix (/usr, baked in at
# Node's own ./configure time, matching every other package's install
# location on this system). A root-owned /usr/lib/node_modules install
# (the original approach here, changed 2026-08-26) means Claude Code's own
# self-updater can't write to its own install directory -- it needs to run
# as the user who'll actually use it and own every file under its prefix.
# Needs working DNS inside the chroot, which the LFS resolv.conf symlink
# cannot provide here.
set -e

# The chroot inherits host networking, but /etc/resolv.conf is a symlink to
# systemd-resolved's stub, which does not exist without a running resolved. Supply
# DNS for the duration of the install and restore the symlink no matter what.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

# Runs as the john user, not root -- npm's global prefix must be writable
# without sudo for both this install and every future self-update.
sudo -u john bash -c '
  set -e
  mkdir -p "$HOME/.npm-global"
  npm config set prefix "$HOME/.npm-global"
  npm install -g @anthropic-ai/claude-code
'

# ~/.npm-global/bin ahead of /usr/bin in john'\''s PATH -- see ~/.bash_profile
# (pathprepend "$HOME/.npm-global/bin", added ahead of the $HOME/bin block).

echo "### versions"
node --version
npm --version
sudo -u john bash -lc 'claude --version'

