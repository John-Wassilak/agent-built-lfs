#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# source: github.com/intel/Intel-Linux-Processor-Microcode-Data-Files, tag microcode-20260812
#
# rationale: host.toml has carried `hw.microcode = 0xc6 loaded, but 'Vulnerability Old
# microcode: Vulnerable' -- update via an early-load initrd, same pattern as server's
# blfs-intel-microcode` since the 2026-08-28 hardware audit, and the 2026-09-04
# post-reboot sweep confirmed nothing had changed: /proc/cpuinfo still reports
# `microcode: 0xc6`, and /sys/devices/system/cpu/vulnerabilities/ still reports
# `old_microcode: Vulnerable` plus six more that say "no microcode" or want a newer
# revision -- gather_data_sampling, mds, mmio_stale_data, srbds, tsx_async_abort and
# vmscape.
#
# This CPU is family 6, model 78 (0x4e), stepping 3 -> blob 06-4e-03, read off
# /proc/cpuinfo rather than assumed from the marketing name. Intel's own releasenote.md
# in this release lists it as `SKL-U/Y  D0  06-4e-03/c0` with a newest revision of
# 0x000000f0, so this takes the part from 0xc6 to 0xf0.
#
# Late loading is not an option: BLFS's firmware.html is explicit that upstream no
# longer supports it (the kernel taints and warns), and this kernel is built
# `# CONFIG_MICROCODE_LATE_LOADING is not set` anyway. Early loading from a dedicated
# initrd is the endorsed path, and CONFIG_MICROCODE=y is already on from defconfig -- no
# kernel change is needed for this, which was checked before the 2026-09-04 thermal
# rebuild rather than discovered after it.
#
# Same deliberate exception to the no-initramfs design that server made for the same
# reason: this initrd carries one file, the microcode blob, and is not a general-purpose
# early-boot environment. Root is still found by root=PARTUUID= with no help from it.
#
# Host-specific, not shared: it names one CPU's blob. server's copy of this recipe
# fetches 06-2a-07 for its i5-2500K and is otherwise the same shape.
set -e

MC_REL=microcode-20260812
MC_BLOB=06-4e-03

# Work in a temp directory that is cleaned up on any exit. This step's plan entry has
# tarball="" -- there is nothing for the driver to unpack -- so it has no source
# directory to cd into and runs with the working directory it was invoked from. On
# 2026-09-04 that was the repo checkout itself, and the first run of this recipe left an
# 18 MB `microcode-src/` and an `initrd/` sitting untracked in the repo root. server's
# copy has the same shape and the same exposure; it has simply never been run from a
# checkout. Recipes that fetch their own source must not assume where they are standing.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

curl -fsSL --retry 5 --retry-delay 3 -o microcode.tar.gz \
    "https://api.github.com/repos/intel/Intel-Linux-Processor-Microcode-Data-Files/tarball/$MC_REL"
mkdir -p microcode-src
tar -xf microcode.tar.gz --strip-components=1 -C microcode-src

[ -f "microcode-src/intel-ucode/$MC_BLOB" ] || {
    echo "intel-microcode: $MC_REL has no blob $MC_BLOB -- wrong release or wrong CPU" >&2
    exit 1
}

mkdir -p initrd/kernel/x86/microcode
cp -v "microcode-src/intel-ucode/$MC_BLOB" initrd/kernel/x86/microcode/GenuineIntel.bin
( cd initrd && find * | cpio -o -H newc > /boot/microcode.img )

# --- wire it into grub.cfg ---------------------------------------------------------
# /boot is not a separate partition here (same as server), so the in-root path form is
# right. Unlike server, this grub.cfg has several menuentries -- the current kernel plus
# one fallback per kernel rebuild -- and every one of them wants the microcode, so this
# inserts after *each* `linux /boot/vmlinuz` line rather than treating the file as
# all-or-nothing. Written in python rather than server's sed so that:
#
#   - a re-run is idempotent per entry (an entry that already carries the line is left
#     alone), which server's single `grep -q` guard cannot manage once a new menuentry
#     is appended later; and
#   - the inserted line copies the indentation of the `linux` line it follows, so it
#     matches this file's 4-space style instead of server's 8.
python3 - <<'PY'
import re
p = "/boot/grub/grub.cfg"
lines = open(p).read().splitlines(keepends=True)
out, added = [], 0
for i, line in enumerate(lines):
    out.append(line)
    if re.match(r"^[ \t]*linux /boot/vmlinuz", line):
        nxt = lines[i + 1] if i + 1 < len(lines) else ""
        if re.match(r"^[ \t]*initrd /boot/microcode\.img", nxt):
            continue
        indent = re.match(r"^[ \t]*", line).group(0)
        out.append("%sinitrd /boot/microcode.img\n" % indent)
        added += 1
open(p, "w").write("".join(out))
print("### added the microcode initrd to %d menuentry(ies)" % added)
PY

grub-script-check /boot/grub/grub.cfg

echo "### grub.cfg:"
cat /boot/grub/grub.cfg
echo "### initrd:"
ls -l /boot/microcode.img
cpio -itv < /boot/microcode.img
