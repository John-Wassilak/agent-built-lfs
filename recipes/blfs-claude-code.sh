#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Installs Claude Code from npm. Needs working DNS inside the chroot, which the LFS resolv.conf symlink cannot provide here.
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

npm install -g @anthropic-ai/claude-code

echo "### versions"
node --version
npm --version
claude --version

