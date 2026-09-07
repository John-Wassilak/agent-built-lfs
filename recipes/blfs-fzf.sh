#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for fzf.
# source: github.com/junegunn/fzf, tag v0.74.3 (commit 15f64c49, 2026-08-17)
# rationale: Operator-requested (2026-09-07). ifd-time-sync's lib/ui.py shells
# out to `fzf` for every interactive pick (Harvest project, Harvest task) and
# prints "fzf not found" and returns None without it, so the tool is unusable
# on this host until fzf exists. General-purpose interactive filter, portable,
# no host-specific content -- shared recipe.
#
# Pure Go, no cgo, builds clean under this project's go1.27.0 (fzf's go.mod
# floor is go1.23.0). Built with `go build` directly rather than the repo's own
# `make`: the Makefile derives $VERSION/$REVISION from `git describe`/`git log`
# and hard-errors ("Not on git repository") against a release tarball, which
# has no .git. The two -X flags below supply exactly what those two variables
# would have been, so `fzf --version` reports the real release and commit
# rather than the in-tree "0.74"/"devel" defaults from main.go. -trimpath and
# -ldflags "-s -w" match upstream's own BUILD_FLAGS.
#
# Shell integration: /etc/profile.d/fzf.sh evals `fzf --bash`, fzf's own
# built-in integration since 0.48 (CTRL-T file widget, CTRL-R history search,
# ALT-C cd widget, and ** completion). That replaces installing the four
# shell/completion.bash + shell/key-bindings.bash files by hand and cannot
# drift from the binary. Bash only -- no zsh or fish on this host.
#
# Deliberately not installed: bin/fzf-tmux and man/man1/fzf-tmux.1 (no tmux in
# this build's closure), bin/fzf-preview.sh (a demo script), and the
# install/uninstall scripts (they exist to bootstrap fzf into a dotfile-managed
# $HOME, which this project's profile.d handles instead).
set -e

FZF_VERSION=0.74.3
FZF_REVISION=15f64c49

# Same $HOME gap as blfs-go.sh/blfs-tailscale.sh: go build needs it (GOPATH,
# GOMODCACHE and GOCACHE all default from $HOME) and a headless systemd-run
# invocation has none.
export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
export CGO_ENABLED=0

# Module and build caches pinned under /root/build-fzf rather than the default
# $HOME/go + $HOME/.cache/go-build. Two reasons, both learned on tailscale
# (see blfs-tailscale.sh): $HOME/go is NOT in bin/lfsbuild's MANIFEST_NOISE
# list, so a freshly written module cache gets swept into this package's
# manifest as if fzf had installed it; and the cache is build scratch worth
# hundreds of MB. /root/build* IS excluded by MANIFEST_NOISE, and the tree is
# removed at the end regardless.
WORK=/root/build-fzf
mkdir -p "$WORK"
export GOPATH="$WORK/gopath"
export GOMODCACHE="$WORK/gopath/pkg/mod"
export GOCACHE="$WORK/gocache"

# DNS fix, same as every other live-network-fetch recipe here (blfs-go.sh,
# blfs-tailscale.sh, blfs-matugen.sh): this tarball ships no vendor/ directory
# (confirmed by inspection -- 0 paths under vendor/), so `go build` fetches all
# eleven module dependencies live. Harmless on a host where DNS already works.
_cleanup() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    rm -rf "$WORK"
}
trap _cleanup EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf

go build -trimpath \
    -ldflags "-s -w -X main.version=$FZF_VERSION -X main.revision=$FZF_REVISION" \
    -o fzf .

install -v -m755 fzf /usr/bin/fzf

install -v -d /usr/share/man/man1
install -v -m644 man/man1/fzf.1 /usr/share/man/man1/fzf.1

install -v -d /usr/share/licenses/fzf
install -v -m644 LICENSE /usr/share/licenses/fzf/LICENSE

cat > /etc/profile.d/fzf.sh << "ENDOFPROFILE"
# Begin /etc/profile.d/fzf.sh

# fzf's own built-in Bash integration (CTRL-T, CTRL-R, ALT-C, ** completion).
# Interactive shells only: `fzf --bash` emits `bind` and `complete` calls that
# are meaningless -- and noisy -- in a non-interactive shell.
if [ -n "${BASH_VERSION-}" ] && [ -n "${PS1-}" ] && command -v fzf > /dev/null; then
    eval "$(fzf --bash)"
fi

# End /etc/profile.d/fzf.sh
ENDOFPROFILE
chmod 644 /etc/profile.d/fzf.sh

echo "### version"
/usr/bin/fzf --version
