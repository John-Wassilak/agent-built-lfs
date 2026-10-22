#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: The Vietnamese engine for fcitx5: Telex, VNI, VIQR and others, with
# spell-checked tone placement. Chosen over fcitx5-unikey for its broader typing-method
# set and active upstream. Its core is Go (bamboo-core, vendored in the tarball, no
# module downloads), built by CMake as a c-archive with this host's /opt/go. Vietnamese
# input closure (operator request, 2026-10-21), see blfs-fcitx5.
# source: download.fcitx-im.org/fcitx5/fcitx5-bamboo/fcitx5-bamboo-1.0.11.tar.zst.
# Detached signature verified good against Weng Xuetian's key
# 2CC8A0609AD2A479C65B6D5C8E8B898CBF2412F9. sha256
# f11be23665dd250a508fb4369e44ad328a6c9923a949487ab38bf470257d047c.
set -e

export HOME="${HOME:-/root}"
export PATH="/opt/go/bin:$PATH"
# Vendored sources only: fail rather than reach for proxy.golang.org.
export GOFLAGS=-mod=mod GOPROXY=off

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release -W no-dev
cmake --build build
cmake --install build
