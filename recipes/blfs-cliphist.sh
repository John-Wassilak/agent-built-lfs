#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for cliphist. Rationale:
# operator-requested clipboard history for the Hyprland desktop stack
# (SUPER+D wofi launcher was already in place; this is the clipboard half).
# source: go.senan.xyz/cliphist (module path per its own go.mod; the GitHub
#   mirror is github.com/sentriz/cliphist), built via `go install`.
# Required: go (this project's own hand-built /opt/go toolchain, see
#   blfs-go.sh), network access for Go module resolution (proxy.golang.org).
#
# `go install` writes to $GOBIN, not a fixed prefix, so build as john into a
# scratch GOBIN and copy the resulting binary into /usr/bin as root --
# matches where this project's other hand-built user tools (e.g. alacritty)
# ended up, rather than /usr/local/bin.
set -e

export PATH=/opt/go/bin:$PATH

sudo -u john bash -c '
  set -e
  mkdir -p /tmp/gobin
  GOBIN=/tmp/gobin go install go.senan.xyz/cliphist@latest
'

install -v -m755 /tmp/gobin/cliphist /usr/bin/cliphist
rm -rf /tmp/gobin

cliphist version
