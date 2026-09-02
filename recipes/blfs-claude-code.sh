#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for Claude Code.
# rationale: operator-requested, installed at the user level (not system-wide) for
# john via npm, matching how it's actually used day to day rather than as a root-
# owned system tool. npm's own global prefix defaults to a root-owned system path;
# reconfigured to a directory under john's own $HOME instead, so `npm install -g`
# needs no elevated privilege and every installed file is owned by john.
set -e

# DNS fix: npm needs live internet to reach registry.npmjs.org. Same fix as every
# other live-fetch recipe in this build (go, tailscale, rust, cargo-c, cbindgen,
# librsvg, hyprland) -- this chroot has no working /etc/resolv.conf by default.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

su - john -c '
set -e
npm config set prefix "$HOME/.npm-global"
npm install -g @anthropic-ai/claude-code
'

# Make the user-level install directory's bin reachable for john specifically --
# not a system-wide /etc/profile.d addition, since this is deliberately a
# per-user, not system, install.
if ! grep -q "npm-global/bin" /home/john/.bashrc; then
    cat >> /home/john/.bashrc << "EOF"

# Added for Claude Code (user-level npm install)
export PATH="$HOME/.npm-global/bin:$PATH"
EOF
fi

echo "### version"
su - john -c 'export PATH="$HOME/.npm-global/bin:$PATH"; claude --version' 2>&1 || true
