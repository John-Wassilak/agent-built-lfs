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
# source, not assumed from docs) and extracts it to a runtime dir under
# /run/user/$UID/danklinux-shell/ at first run, then shells out to the
# `quickshell` binary this project just built. matugen (built separately,
# seq before this) provides the actual Material You wallpaper theming DMS's
# own README calls its main feature; dgop/dsearch (system telemetry /
# launcher search) are optional companion tools per DMS's own docs ("Only
# Quickshell is required") and not built here.
#
# PATCH (2026-09-04, live-verification fallout): DMSShell.qml unconditionally
# instantiates `Lock {}` (quickshell/Modules/Lock/Lock.qml), whose Pam.qml
# does `import Quickshell.Services.Pam` -- a module this host's quickshell
# does not have (built with -D SERVICE_PAM=OFF, hosts/laptop/recipes/blfs-
# quickshell.sh, because this host deliberately never built Linux-PAM: BLFS's
# own linux-pam.html requires reinstalling Shadow *and* Systemd afterward, a
# real risk on a live daily-driver this project has already decided against).
# QML fails DMSShell.qml's *entire* document load over this one unresolvable
# type -- confirmed live via `qs:@/qs/DMSShell.qml[61:5]: Type Lock
# unavailable` -- which takes down every popout/dropdown in the shell (dash,
# control center, battery, calendar, everything), not just the lock screen,
# since DMSShell.qml is what hosts all of their Loaders. The bar itself
# renders fine regardless, since it's a separate document -- this is why
# every dropdown failed identically with the button still visibly responding
# to clicks, and no error anywhere else.
#
# Fix: patch quickshell/Modules/Lock/Pam.qml (in the freshly cloned source,
# before `make build` embeds it) to drop the `Quickshell.Services.Pam`
# import and inline PamResult's four enum values as plain properties, and
# add a same-directory PamContext.qml stand-in with the same property/
# function surface Pam.qml already uses (config, configDirectory, active,
# message, responseRequired, start(), abort(), respond(), completed(result)
# signal) -- all inert (active always false, functions no-op). PamContext/
# PamResult are used nowhere outside Pam.qml (confirmed by grep), so this is
# fully contained. Net effect: the lock screen's actual unlock still never
# succeeds -- an already-accepted tradeoff -- but the rest of the shell no
# longer fails to load because of it. Verified live before writing this:
# patched the already-running instance's extracted copy by hand first,
# confirmed `dms:bar`'s dropdowns (calendar, cpu/mem, bluetooth, all of them)
# open correctly, *then* folded the same patch back into this recipe so a
# future rebuild doesn't regress it.
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

cd /sources
rm -rf DankMaterialShell
git clone --branch v1.6.0 --recurse-submodules --shallow-submodules --depth 1 \
    https://github.com/AvengeMedia/DankMaterialShell.git
cd DankMaterialShell/core

make sync-shell

# See the PATCH note above the shebang for the full rationale.
LOCKDIR=../quickshell/Modules/Lock
sed -i \
    -e '/^import Quickshell\.Services\.Pam$/d' \
    -e '/^    id: root$/a\
\
    readonly property int pamResultSuccess: 0\
    readonly property int pamResultError: 1\
    readonly property int pamResultMaxTries: 2\
    readonly property int pamResultFailed: 3' \
    -e 's/PamResult\.Success/root.pamResultSuccess/g' \
    -e 's/PamResult\.Error/root.pamResultError/g' \
    -e 's/PamResult\.MaxTries/root.pamResultMaxTries/g' \
    -e 's/PamResult\.Failed/root.pamResultFailed/g' \
    "$LOCKDIR/Pam.qml"
cat > "$LOCKDIR/PamContext.qml" << "EOF"
import QtQuick

// Stub replacement for Quickshell.Services.Pam's PamContext, used when
// quickshell was built with -D SERVICE_PAM=OFF (no Linux-PAM on this host --
// see this recipe's own PATCH note above). Never actually authenticates;
// exists only so Pam.qml (and anything instantiating Pam{} -- Lock.qml,
// LockScreenContent.qml) can still load without the real
// Quickshell.Services.Pam module. Real unlock never succeeds (an
// already-accepted tradeoff), but the rest of the shell no longer fails to
// load because of it.

QtObject {
    property string config: ""
    property string configDirectory: ""

    readonly property bool active: false
    readonly property string message: ""
    readonly property bool responseRequired: false

    signal completed(result: int)

    function start(): void {}
    function abort(): void {}
    function respond(response: string): void {}
}
EOF

make build
make install PREFIX=/usr

echo "### version"
/usr/bin/dms version 2>&1 || true

# Same cache-cleanup reasoning as blfs-tailscale.sh: this tarball-free build
# fetches every Go module dependency live (no vendor/ directory), into
# $HOME/go and $HOME/.cache/go-build -- build-time scratch, not installed.
rm -rf "$HOME/go" "$HOME/.cache/go-build"
