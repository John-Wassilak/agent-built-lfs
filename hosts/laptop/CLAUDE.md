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
- **This host is still pinned to LFS/BLFS 13.0 (`host.toml`'s `[books]`) while `server`
  moved to 13.1 on 2026-09-07.** The shared `recipes/` tree is machine-neutral only when
  every host reads the same book version -- that stopped being true the moment `server`
  bumped, and the tooling has no version-scoping for the shared tree, only for the
  chunked book HTML it reads from. Concretely: `bin/extract-recipes.py --host laptop
  --check` / `bin/extract-blfs.py --host laptop --check` will report drift on ~240 pages
  where this host has no `hosts/laptop/recipes/<name>.sh` copy of its own -- that is
  **expected noise from the version gap, not real drift** (confirmed 2026-09-07: this
  host's own book/13.0-based rendering is unchanged from before the bump; only the
  *shared* candidate file changed, since `server`'s 13.1 extraction run overwrote it).
  **Do not run `lfsbuild --host laptop --only <step> --force` for any step this host has
  no `hosts/laptop/recipes/` copy of without first checking whether that step's page
  changed between `book/13.0` and `book/blfs-13.0` vs `book/13.1`/`book/blfs-13.1`** --
  the shared recipe may now assume a different toolchain/library version than what this
  host is actually built against. Six pages are confirmed to need this care because they
  had real command-content changes carried a stale block-index into the shared file
  during the bump (`ch08-gcc`, `blfs-nodejs`, `blfs-sudo`, `blfs-glib2`, `blfs-rust`,
  `blfs-json-c`) -- each now has a `hosts/laptop/`-level compat override restoring the
  correct 13.0-era decision, tagged "Remove once this host also bumps to 13.1" in its
  `reason`. The other ~240 pages were not individually re-verified against 13.1 text
  (out of scope for server's bump); their shared recipe is now 13.1-shaped by default.
  The clean fix, whenever this host's own bump happens, is to do the same 13.0->13.1
  migration review this host still owes, at which point these compat overrides and this
  whole note can be deleted. A better structural fix -- version-scoping `recipes/`
  itself (e.g. `recipes/<family>-<ver>/`) so two hosts on different book versions never
  share one candidate file -- was identified but not implemented; flag it if a third
  host or another cross-version gap appears.

Site data is untracked on purpose. `etc-hosts.local` and `authorized-keys.local` hold this
machine's LAN/VPN map and its SSH access list; both are gitignored with tracked `.example`
templates, staged into `/sources` before a build, and read by `ch09-network` and
`blfs-authorized-keys-john`. They were inline in the tracked recipes until 2026-09-21 --
do not move them back. The repo is public.
