#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- shared recipe: herdr, a terminal multiplexer for coding agents
# Copyright (c) 2026 John Wassilak
#
# HAND-AUTHORED recipe -- no BLFS book page for herdr.
# source: github.com/herdrdev/herdr, release v0.9.5 (2026-10-14), Apache-2.0.
#
# rationale: operator request 2026-11-13. herdr runs coding agents (Claude Code and
# others) in persistent panes and workspaces that survive a detach.
#
# Upstream's prebuilt binary, not a source build. Checked against the v0.9.5 tree
# before choosing this (2026-11-13, laptop):
#   - crates/ghostty-vt/build.rs compiles the vendored libghostty-vt with `zig build`
#     and fails without Zig 0.16.0. No machine here has Zig.
#   - rust-toolchain.toml pins 1.96.1. BLFS 13.0's rustc is 1.93.1.
# The release asset is a static-pie x86_64 executable (`file`, `ldd`: "statically
# linked"), so it needs nothing from this system's libraries. Its sha256 is pinned
# below from GitHub's asset digest and was checked against a download before use.
# A source build becomes possible if Zig 0.16 and Rust >= 1.96 are ever built here.
#
# Updates: herdr checks for new releases in the background and shows a notice, but it
# installs nothing until someone runs `herdr update`. Do not run that: it would replace
# /usr/bin/herdr behind lfsmaint's back. Bump the version and digest here and rebuild
# the step instead. `[update] version_check = false` in ~/.config/herdr/config.toml
# silences the notice.
set -e

HERDR_VERSION=0.9.5
HERDR_SHA256=14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d

if [ "$(uname -m)" != x86_64 ]; then
    echo "herdr: this recipe pins the x86_64 asset; $(uname -m) needs its own digest" >&2
    exit 1
fi

# DNS: the chroot has no working resolver; a native host does, and may pin its
# resolver (laptop and server both point at pi-router since 98e2c28). Only fall back
# to the public-resolver fix the other live-fetch recipes use when lookup fails.
if ! getent hosts github.com >/dev/null; then
    _restore_resolv() {
        rm -f /etc/resolv.conf
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    }
    trap _restore_resolv EXIT
    rm -f /etc/resolv.conf
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf
fi

work=$(mktemp -d)
trap 'rm -rf "$work"; declare -F _restore_resolv >/dev/null && _restore_resolv' EXIT

curl -fsSL --retry 5 --retry-delay 3 -o "$work/herdr" \
    "https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/herdr-linux-x86_64"
echo "${HERDR_SHA256}  $work/herdr" | sha256sum -c -

install -v -m755 "$work/herdr" /usr/bin/herdr

install -v -d /usr/share/bash-completion/completions /usr/share/zsh/site-functions
/usr/bin/herdr completion bash > /usr/share/bash-completion/completions/herdr
/usr/bin/herdr completion zsh  > /usr/share/zsh/site-functions/_herdr

echo "### version"
/usr/bin/herdr --version
