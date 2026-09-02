# `laptop`

Hardware audited 2026-08-28 (`BUILD-REPORT.md`, `host.toml`'s `[hardware]`). Not built
yet. `packages.py` is still `BASE` alone -- the Hyprland/pipewire tiers get added
just-in-time against the real book text, once `book/` is fetched, not written ahead of it.

`BOOTSTRAP.md` is the procedure, revised for the decisions below. Read it before anything
else here.

Things worth knowing before changing anything here:

- **This is a ThinkPad X1 Carbon Gen 4 (Skylake, i7-6600U, HD Graphics 520), and it is
  the operator's daily driver.** Treat disk and CPU headroom as real constraints, not
  suggestions -- `build.jobs = 2` in `host.toml` is a deliberate cap (this machine has 4
  threads), and space is genuinely tight (see below). Do not raise either without asking.
- **Target desktop is Hyprland / Wayland / pipewire, decided from the start** (operator,
  2026-08-28) -- unlike `server`, where Wayland was ruled out mid-build by a Kepler-era
  NVIDIA driver. This GPU has a fully open, current `i915` driver; nothing here should
  need the kind of GPU-forced compromise `server`'s `HYPRLAND-PLAN.md` hit. That document
  is still the right reference for *how* to build the stack (BLFS-page-first, Arch
  `extra` PKGBUILDs as the sourcing policy for what BLFS doesn't carry, tier order) --
  just substitute Intel/`iris` for NVIDIA/`nouveau` throughout, and pipewire (+
  `pipewire-pulse`) as the actual audio target rather than building real PulseAudio.
- **There is no free disk space on this machine**, and no unpartitioned space to make
  any -- the 238.5G NVMe is fully carved up already. Operator decision: build the chroot
  tree inside this repo checkout (`host.toml`'s `chroot_tree`, gitignored under `/lfs/`)
  instead of a dedicated partition, watch free space by hand while building, get as much
  of LFS+BLFS built as fits, then `bin/lfs-archive --tree --final` it and deploy the
  tarball to the existing `nvme0n1p1` (reformatted) from USB rescue media. Do not propose
  repartitioning or a dedicated LFS partition without asking first -- that was explicitly
  considered and declined in favor of this path.
- **Boot mode is legacy BIOS/MBR**, matching how the machine boots today, even though the
  hardware supports UEFI -- operator decision, because the deploy step reuses the
  existing MBR partition table rather than repartitioning to GPT.
- **Audio codec is Conexant, not Realtek** -- checked against `/proc/asound/cards`, not
  assumed. `server`'s kernel-config.sh stub template guesses Realtek by default; this
  machine's `kernel-config.sh` does not need that correction repeated.
- **`nvme0n1p3` (the LUKS `/mnt/crypt` volume, this repo's own home) is never touched by
  any of this build or deploy process.** Only `nvme0n1p1` (root) and `nvme0n1p2` (swap)
  get reformatted at deploy time.
