#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this (same category as
# linux-firmware-rtl-nic).
# rationale: GPU deep-dive (2026-08-26) found nouveau's msvld/mspdec/msppp
# (the actual video decode/post-processing engines) failing to load
# firmware at all -- `Direct firmware load for nouveau/nve4_fuc084 failed
# with error -2` in dmesg, for all three engines. This is a real, separate
# gap from Mesa's VAAPI profile advertisement (vainfo lists profiles from
# a static gallium capability table, independent of whether this engine
# firmware ever loaded) -- likely the actual root cause of the earlier
# "H.264 High profile advertised but rejected at runtime" finding.
#
# This firmware is legitimately non-redistributable through the normal
# linux-firmware tree -- confirmed via nouveau's own wiki
# (nouveau.freedesktop.org/VideoAcceleration.html): "We cannot
# redistribute the firmware directly in linux-firmware because NVIDIA's
# license forbids redistribution of parts of their driver." The sanctioned
# path is extracting it yourself from NVIDIA's own official driver
# installer via nouveau's own `extract_firmware.py` (envytools project) --
# producing exactly the file/symlink layout used below (a single combined
# blob per engine, e.g. `nve0_bsp`, with `nve4_fuc08x` symlinks pointing
# at it, matching the format `nvkm_falcon_init()` tries FIRST per this
# system's own running kernel source, drivers/gpu/drm/nouveau/nvkm/engine/
# falcon.c).
#
# Source used here: this exact file set already existed on this machine's
# own previous Gentoo install (/mnt/big_drive/usr/lib/firmware/nouveau/,
# the second drive, still mounted). Gentoo is one of only two distros
# nouveau's wiki names as legitimately shipping this firmware pre-packaged,
# and the file/symlink layout matches the documented extraction output
# exactly -- reused rather than re-extracted from a fresh NVIDIA installer
# download, since the result is identical and the provenance (this same
# physical machine's own prior install) is solid.
set -e

install -vdm755 /usr/lib/firmware/nouveau

cp -v /mnt/big_drive/usr/lib/firmware/nouveau/nve0_bsp \
      /mnt/big_drive/usr/lib/firmware/nouveau/nve0_vp  \
      /mnt/big_drive/usr/lib/firmware/nouveau/nvc0_ppp \
      /usr/lib/firmware/nouveau/

ln -svf nve0_bsp /usr/lib/firmware/nouveau/nve4_fuc084   # msvld  (video decode)
ln -svf nve0_vp  /usr/lib/firmware/nouveau/nve4_fuc085   # mspdec (picture decode)
ln -svf nvc0_ppp /usr/lib/firmware/nouveau/nve4_fuc086   # msppp  (post-processing)

chown -R root:root /usr/lib/firmware/nouveau

echo "### installed:"
ls -l /usr/lib/firmware/nouveau/

echo "### requires a nouveau module reload (or reboot) to take effect --"
echo "### not done automatically here, since a live driver reload can"
echo "### disrupt an active DRM/compositor session."
