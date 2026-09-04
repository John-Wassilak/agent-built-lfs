#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for DankMaterialShell.
# source: github.com/AvengeMedia/DankMaterialShell, tag v1.6.0, cloned directly
# (not a tarball fetch, like this project's own htop recipe) because the real
# QML tree lives partly in a git submodule (dank-qml-common, its own tag v1.6.0,
# symlinked in as quickshell/DankCommon) that a plain GitHub archive tarball
# does not populate -- confirmed by inspecting the tarball directly before
# writing this: dank-qml-common/ exists but is empty in the archive.
#
# rationale: operator-requested (2026-09-04). Not compiled QML -- Quickshell
# loads it directly at runtime. What IS compiled is a companion Go binary
# (core/, this project's own already-built go1.27.0 satisfies its go.mod
# floor of go1.26.5) that embeds the entire QML tree via go:embed
# (core/internal/shellembed, confirmed by reading the actual Makefile and Go
# source, not assumed from docs) and extracts it to ~/.config/quickshell/dms
# at first run, then shells out to the `quickshell` binary this project just
# built. matugen (built separately, seq before this) provides the actual
# Material You wallpaper theming DMS's own README calls its main feature;
# dgop/dsearch (system telemetry / launcher search) are optional companion
# tools per DMS's own docs ("Only Quickshell is required") and not built here.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export CGO_ENABLED=0

# Same DNS gap as blfs-go.sh/blfs-tailscale.sh/blfs-matugen.sh.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

rm -rf DankMaterialShell
git clone --branch v1.6.0 --recurse-submodules --shallow-submodules --depth 1 \
    https://github.com/AvengeMedia/DankMaterialShell.git
cd DankMaterialShell/core

make sync-shell
make build
make install PREFIX=/usr

echo "### version"
/usr/bin/dms --version 2>&1 || true

# Same cache-cleanup reasoning as blfs-tailscale.sh: this tarball-free build
# fetches every Go module dependency live (no vendor/ directory), into
# $HOME/go and $HOME/.cache/go-build -- build-time scratch, not installed.
rm -rf "$HOME/go" "$HOME/.cache/go-build"
