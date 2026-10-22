#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for virtiofsd.
# source: gitlab.com/virtio-fs/virtiofsd, tag v1.14.0 (released 2026-07-06), GitLab
# archive tarball. Arch carries it in [extra].
#
# rationale: the vhost-user daemon behind qemu's vhost-user-fs-pci device, which shares a
# host directory with a guest. qemu dropped its own C virtiofsd in 8.0; this Rust one is
# the replacement. Added 2026-10-22 so server's Windows guest sees
# /mnt/big_drive/vm/share as a drive (packages.py seq 275). The Windows side is
# virtio-win's viofs driver and VirtioFsSvc, plus WinFsp.
#
# Build deps, all present before this step: Rust/cargo (BLFS, on PATH from
# /etc/profile.d/rustc.sh), libseccomp, libcap-ng (previous step).
#
# cargo fetches the crates Cargo.lock pins from crates.io; --locked holds it to those
# exact versions. CARGO_HOME sits in the build tree, so the registry cache is removed
# with the source and never reaches the manifest.
#
# Installed where the Arch package puts it: the binary in /usr/libexec, which is
# the path upstream's 50-virtiofsd.json names, and that descriptor (qemu's vhost-user
# discovery file) in /usr/share/qemu/vhost-user.
set -e

export CARGO_HOME="$PWD/.cargo-home"

cargo build --release --locked

install -v -m755 -D target/release/virtiofsd /usr/libexec/virtiofsd
install -v -m644 -D 50-virtiofsd.json /usr/share/qemu/vhost-user/50-virtiofsd.json

echo "### version"
/usr/libexec/virtiofsd --version
