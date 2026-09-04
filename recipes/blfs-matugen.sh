#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for matugen.
# rationale: Not in the BLFS 13.0 book, not an AUR/PKGBUILD reference this time --
# a real Rust crate (crates.io/crates/matugen, github.com/InioX/matugen), and
# `cargo install` is the standard, correct way to get a Rust binary from crates.io,
# same class of call as this build's earlier `pip install markdown` for GTK4 (a
# language toolchain's own package manager, already built and proven working here,
# rather than a hand-rolled source fetch). DankMaterialShell's own README:
# wallpaper-based Material You color scheme generation is what this actually
# provides -- listed as optional by DMS's own docs ("Only Quickshell is required"),
# but it is the real point of "Material" in DankMaterialShell's name.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/rustc-1.93.1/bin:$PATH"

# Same DNS gap every other live-network-fetch recipe in this build hits
# (blfs-go.sh, blfs-tailscale.sh): cargo fetches crates.io and every
# dependency live, and this project's native systemd-run invocation
# doesn't have a working /etc/resolv.conf by default.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

cargo install --root /usr --locked matugen

echo "### version"
matugen --version

# Cache cleanup, same reason as blfs-tailscale.sh's $HOME/go cleanup:
# cargo install leaves its build tree and registry cache in $HOME/.cargo
# and a temporary target/ dir -- build-time scratch space, not an
# installed artifact, and would otherwise get swept into the manifest by
# the driver's own -cnewer capture.
rm -rf "$HOME/.cargo/registry" "$HOME/.cargo/git"
