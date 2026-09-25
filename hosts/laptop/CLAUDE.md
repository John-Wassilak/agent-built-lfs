# `laptop`

Hardware audited 2026-08-28 (`BUILD-REPORT.md`, `host.toml`'s `[hardware]`). `packages.py`
has grown well past `BASE` -- BLFS/Hyprland desktop, pass/gnupg/bluez, pipewire/
wireplumber, and more -- added just-in-time against the real book text as each tier was
reached, not written ahead of it.

**This machine is real LFS now, not Gentoo.** The original plan (chroot build under
`/mnt/crypt`, archive with `bin/lfs-archive --tree --final`, deploy to `nvme0n1p1` from
USB rescue media, reboot) actually succeeded: `17c4112` ("deploy to nvme0n1p1") did the
deploy, and `/etc/os-release` on this box now reads `ID=lfs`. Gentoo was only ever the
pre-deploy host distro this was built from. Every session since has correctly built
further BLFS packages with `--native` against that real, deployed root, per
`BOOTSTRAP.md`'s own step 6 -- the pre-deploy chroot tree under `/mnt/crypt` was left
over from before the deploy, went stale, and confused `lfsbuild`'s mode auto-detection
for a whole session before being noticed and removed 2026-09-04. `host.toml`'s
`build.mode = "native"` now pins the mode so that auto-detection can't get it wrong
again regardless of what does or doesn't exist at `chroot_tree`.

`BOOTSTRAP.md` is the procedure, revised for the decisions below. Read it before anything
else here.

Things worth knowing before changing anything here:

- **This is a ThinkPad X1 Carbon Gen 4 (Skylake, i7-6600U, HD Graphics 520), and it is
  the operator's daily driver.** Treat disk and CPU headroom as real constraints, not
  suggestions. `build.jobs` is **4** as of 2026-09-04 (operator decision), using all four
  threads -- `nproc` is 4, from 2 physical Skylake-U cores with 2 threads each. It was
  originally capped at 2 to keep the machine usable during a build; that cap is gone.
  qt6 was once thought to need dropping back to 2 (see the 2026-09-04 disk/memory
  incidents in `BUILD-REPORT.md`), but that turned out to be the untrimmed ~40-module
  build compiling qtwebengine by accident, not qt6 itself -- the real trimmed 6-module
  build this host uses never exceeded ~3GB RAM even at -j2, confirmed live, so it now
  runs at `-j4` like everything else (hardcoded in the recipe override, since `ninja`
  ignores this file's MAKEFLAGS-based jobs setting -- ninja-based recipes need their
  own explicit `-j` flag, ordinary `make`-based ones don't). Space is genuinely tight
  (see below) -- do not raise disk usage without asking.
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
- **This host is pinned to LFS/BLFS 13.0 (`host.toml`'s `[books]`); `server` moved to
  13.1 on 2026-09-07.** Since `db416ba` (2026-09-21) this host reads its own
  generated recipes and decisions: `recipes/lfs-13.0/`, `recipes/blfs-13.0/`, and so on,
  each with its own `overrides.json`. `server`'s 13.1 extractions write
  `recipes/*-13.1/` and cannot touch them. `extract-blfs.py --host laptop --check`
  exits 0 with zero drift. New decisions for this host's pages go in the 13.0
  `overrides.json`, and they carry to 13.1 only through a re-read. `extract-recipes.py`
  and `extract-slfs.py` cannot run here, because the LFS and SLFS books are not in this
  tree.

  Still cross-version: `packages/base.py` pins tarball versions for every host. This
  host's plan asks for `which-2.25` and `p11-kit-0.26.5`, which are 13.1's, while its
  13.0 pages name 2.23 and 0.26.2. Before rebuilding a BASE step, check the tarball in
  `state/blfs-plan.json` against this host's page.

  Leftover compat overrides, all tagged "Remove once this host also bumps to 13.1":
  `blfs-overrides.json` `blfs-rust` blocks 3-4, and `review-overrides.json` `ch08-gcc`
  blocks 5 and 7. They were written to undo 13.1 decisions leaking into the shared
  file. That no longer happens: `recipes/blfs-13.0/overrides.json` already drops rust
  3-4, and `recipes/lfs-13.0/overrides.json` already has gcc 7 as `test` and no entry
  for block 5. They look redundant, but they have not been removed. The gcc pair can't
  be `--check`ed on this machine, so remove it from a checkout that has the LFS book.
  (`blfs-rust` block 1 in the same file is a real host decision, not a leftover.)

Site data is untracked on purpose. `etc-hosts.local` and `authorized-keys.local` hold this
machine's LAN/VPN map and its SSH access list; both are gitignored with tracked `.example`
templates, staged into `/sources` before a build, and read by `ch09-network` and
`blfs-authorized-keys-john`. They were inline in the tracked recipes until 2026-09-21 --
do not move them back. The repo is public.
