# `laptop` — build report

Nothing built yet. See `BOOTSTRAP.md` for the procedure. `hosts/server/BUILD-REPORT.md` is
the format this file follows: dated sections, appended in order, recording what was built,
what broke, what was measured, and what was decided and why.

## 2026-08-28: baseline hardware audit

Run on the live host distro (Gentoo 2.18, kernel 6.18.39-gentoo-dist-bin), the same box
this will become. Verbatim output, condensed to what mattered:

```
$ cat /sys/class/dmi/id/product_name /sys/class/dmi/id/sys_vendor \
      /sys/class/dmi/id/product_version /sys/class/dmi/id/bios_version
20FRS17200
LENOVO
ThinkPad X1 Carbon 4th
N1FET68W (1.42 )

$ lscpu
Model name:  Intel(R) Core(TM) i7-6600U CPU @ 2.60GHz
CPU(s): 4   Core(s) per socket: 2   Thread(s) per core: 2
CPU max MHz: 3400.0000   CPU min MHz: 400.0000
Vulnerability Old microcode: Vulnerable

$ lspci -k
00:02.0 VGA compatible controller: Intel Corporation Skylake GT2 [HD Graphics 520] (rev 07)
        Kernel driver in use: i915
00:1f.3 Audio device: Intel Corporation Sunrise Point-LP HD Audio (rev 21)
        Kernel driver in use: snd_hda_intel
00:1f.6 Ethernet controller: Intel Corporation Ethernet Connection I219-LM (rev 21)
        Kernel driver in use: e1000e
02:00.0 Unassigned class [ff00]: Realtek RTS525A PCI Express Card Reader (rev 01)
        Kernel driver in use: rtsx_pci
04:00.0 Network controller: Intel Corporation Wireless 8260 (rev 3a)
        Kernel driver in use: iwlwifi
05:00.0 Non-Volatile memory controller: Samsung SM951/PM951 NVMe SSD Controller
        Kernel driver in use: nvme

$ cat /proc/asound/card3/codec#0 | head -1   # the PCH's actual codec chip
Codec: Conexant CX20753/4
$ cat /proc/asound/card3/codec#2 | head -1
Codec: Intel Skylake HDMI

$ lsblk
nvme0n1       238.5G  disk
├─nvme0n1p1     50G  part  /                 (ext4, 6.3G free, 87% used)
├─nvme0n1p2     16G  part  [SWAP]
└─nvme0n1p3  172.5G  part
  └─cryptroot 172.5G crypt /mnt/crypt         (ext4 inside LUKS, 6.9G free, 96% used)

$ [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
BIOS

$ ls /sys/class/power_supply/
AC  BAT0
$ cat /sys/class/power_supply/BAT0/capacity
98
```

**Findings, and what they decide:**

- **CPU**: i7-6600U, Skylake, 2C/4T. `Vulnerability Old microcode: Vulnerable` -- same
  early-load-initrd pattern server needed (`blfs-intel-microcode`), microcode version to
  fetch determined by CPUID at build time, not guessed here.
- **GPU**: Intel HD Graphics 520 (`i915`, in-SoC, no separate PCI vendor decision to
  make). This is the box server's Kepler-generation NVIDIA card could never be: a fully
  open, current, in-kernel driver with real Wayland support. Confirmed the operator's
  Hyprland/Wayland/pipewire target is not fighting the hardware the way it would have on
  server.
- **Audio**: Conexant CX20753/4, not Realtek -- checked `/proc/asound/cards` rather than
  assuming the more common chip. Also HDMI audio (Intel Skylake HDMI codec) and three USB
  audio devices already enumerating cleanly under the live kernel with no force-probe
  quirk, unlike server's misreported codec slots.
- **Wireless**: Intel 8260 (`iwlwifi`) -- needs `iwlwifi-8260` firmware from
  linux-firmware, a BLFS step, not a kernel option.
- **Storage boot path**: NVMe, not SATA -- server's kernel-config-base.sh gate list never
  checks `BLK_DEV_NVME` because server boots SATA. Added to `EXTRA_GATE_BUILTIN` in this
  host's kernel-config.sh so a regression here fails the gate instead of failing at boot.
- **Boot firmware**: BIOS/legacy, confirmed by `/sys/firmware/efi` absent under the live
  Gentoo install, despite the hardware supporting UEFI. Operator decision (2026-08-28):
  match legacy BIOS/MBR rather than switch to UEFI/GPT, since the deploy target reuses
  the existing MBR partition table rather than repartitioning.
- **Disk**: the critical constraint. 238.5G NVMe, fully partitioned across three volumes
  already (50G root, 16G swap, 172.5G LUKS `/mnt/crypt` -- this repo's own location), with
  only 6.3G and 6.9G free respectively and no unpartitioned space at all. A full
  LFS+BLFS Hyprland build is realistically tens of GB (server: 307+ packages, 75k+ files).
  Operator decision (2026-08-28): build LFS in a chroot tree inside this repo checkout
  (`hosts/laptop/host.toml`'s `chroot_tree`, gitignored) rather than on a dedicated
  partition, get as much of LFS+BLFS built as fits while watching free space by hand, then
  archive the finished tree with `bin/lfs-archive --tree --final` and deploy it to the
  existing `nvme0n1p1` (reformatted) from USB rescue media -- the same restore procedure
  `bin/lfs-archive` already prints for a `--live` backup, reused here for a `--tree` image.
  See `BOOTSTRAP.md`'s deploy section.
- **Battery/laptop hardware**: AC + BAT0 present, 98% at audit time. ACPI battery/AC/lid,
  backlight, and `thinkpad_acpi` (ThinkPad-specific brightness/mute/Fn hotkeys, already
  bound under the live kernel) all need kernel config the shared base doesn't carry.
- **Input**: Synaptics touchpad + TrackPoint, both on the PS/2 bus
  (`MOUSE_PS2_SYNAPTICS`) -- not a separate USB/I2C device to chase down.
- **Card reader**: Realtek RTS525A, optional, deferred -- not on the boot path and not
  needed for a first build.

`hosts/laptop/host.toml`'s `[hardware]` table and `hosts/laptop/kernel-config.sh` are
filled in from this audit. `packages.py` still needs the actual BLFS package tiers,
researched just-in-time against `book/blfs-13.0/` once it is fetched, the same policy
server's `HYPRLAND-PLAN.md` used -- not written speculatively ahead of the real book text.

## 2026-08-28 to 2026-08-30: chapters 4-11 built, chroot tree at `lfs/`

133/133 LFS steps complete, ~15.25 build-hours total (`-j2`, per host.toml). Three real
defects found only by letting the real build run, each recorded as a review decision
rather than a hand-edit to the generated recipe:

- **`ch04-settingenvironment` hardcoded `LFS=/mnt/lfs`.** The book's own text is only
  correct because `/mnt/lfs` is also `lfshost.py`'s `DEFAULT_CHROOT_TREE` -- server never
  hit this because it built there. laptop's `chroot_tree` is a directory inside this repo
  instead (no spare partition), so `ch05-binutils-pass1` failed immediately with `mkdir:
  cannot create directory '/mnt/lfs': Permission denied`. The same block also hardcoded
  `MAKEFLAGS=-j$(nproc)` (4 threads), ignoring host.toml's deliberate `-j2` cap -- the
  chroot/root-host contexts get `-j2` from `lfsbuild`'s own exec_argv, but the real `lfs`
  system-user's chapters 5-6 shell has no other source of `MAKEFLAGS` than this dotfile.
  Fixed via a host review-override (`ch04-settingenvironment` blocks 1 and 5), then a
  forced re-run of that one step to regenerate the already-written (and already wrong)
  `~/.bashrc` on the real `lfs` host account before resuming. First host in this repo to
  expose either gap, since server's `chroot_tree` and `jobs` both matched the book's
  defaults.
- **`ch08-perl`'s test suite hung, not failed.** `TEST_JOBS=$(nproc) make test_harness`
  sat for ~17.5 hours; `ps` showed three of Perl's own tests still running
  (`t/nntp_ipv6.t`, `t/pop3_ipv6.t`, `t/smtp_ipv6.t`) plus a `<defunct>` zombie child never
  reaped. These open real IPv6 sockets; at this point in the book the chroot has no
  configured network stack at all, so a `connect()` that would fail fast on a normal
  system instead blocks forever with nothing to time it out. Recovered by killing the
  whole process group (`sudo kill -9 -<pgid>` -- the stuck root-owned chroot subtree
  shared the same PGID as the `lfsbuild` driver itself, so one command took down both
  cleanly). Fixed by dropping the test_harness block entirely via a host override --
  host-scoped rather than shared, since it's unconfirmed whether server's chroot hit the
  same thing or just got lucky on timing.
- **`ch10-kernel`'s `/boot` blocks used the book's literal `cp -iv`.** Same defect server
  already found and fixed the same way (host override, blocks 5-7, `-i` dropped) -- just
  never carried over to laptop until the kernel step was actually reached. Kernel version
  is the book's own LFS 13.0-systemd default, `linux-6.18.10`, coincidentally the same
  number as server's current kernel.
- **Sudo, unattended.** Every step but a handful needs root (chroot itself requires it),
  and this box had no cached or passwordless sudo at all. Rather than a blanket
  `NOPASSWD: ALL`, added `/etc/sudoers.d/lfsbuild-laptop` scoped to the exact command
  shapes `bin/lfsbuild` invokes for this host (verified against `exec_argv()`/`run_step()`
  in the source, not guessed): staging/running generated step scripts under
  `lfs/sources/.build/`, entering the chroot at `lfs/`, and the Chapter 8 manifest
  copy/chown/cleanup. Installed by the operator directly (this session has no TTY for a
  sudo password prompt); not extended to `bin/lfs-archive`/`lfsmaint`/`lfs-umount`, which
  are occasional manual operations rather than a 100+-step unattended loop.

Kernel config gate passed clean on the first real run, including both host-specific
additions from the hardware audit: `NVME_CORE`/`BLK_DEV_NVME` in `EXTRA_GATE_BUILTIN`
(this machine boots NVMe, which the shared gate never checks since server boots SATA),
and the schedutil-governor assertion inherited from the shared base. `/boot` has
`vmlinuz-6.18.10-lfs-13.0-systemd`, `System.map-6.18.10`, `config-6.18.10`.

`ch10-grub` and `ch11-reboot` skipped by design (`SPECIAL` in `lfsbuild`) -- GRUB install
is deferred to the USB deploy phase (no target device yet from inside a chroot build),
and there is no reboot because this tree is not running in place. 83 Chapter 8 manifests
recorded, 14.2G free on `/mnt/crypt` afterward.

Next: BLFS. `packages.py` is still `BASE` alone (16 steps); the Hyprland/Wayland/pipewire
tiers get researched against the real `book/blfs-13.0/` text once reached, not written
ahead of it -- see `hosts/laptop/CLAUDE.md`.

## 2026-08-30: BLFS BASE built -- 17/17 steps, laptop has a working system

`BASE`'s 16 steps plus one host-specific addition (below), all complete. Four more real
gaps found by actually running the build, none of them laptop-specific hardware issues --
mostly this being the first from-scratch BLFS run this repo has actually driven start to
finish rather than following on from server's already-built state:

- **`make-ca` needs Mozilla's raw `certdata.txt`, not just its own tarball.** The book
  says make-ca will download it from `hg-edge.mozilla.org` itself, but the chroot has no
  configured network stack at this point (same reason `ch09-network` is just config
  files, not a live interface) -- `make-ca -f -C /sources/certdata.txt` failed outright
  with `not found!`. Read the exact URL out of `make-ca`'s own source
  (`https://hg-edge.mozilla.org/projects/nss/raw-file/tip/lib/ckfw/builtins/certdata.txt`,
  the same "tip" revision the script would have fetched itself) rather than guessing, and
  staged it via the host's own network into `lfs/sources/` the same way the tarballs were
  staged. `.gitignore` already carried a `blfs-staging/certdata.txt` entry from server's
  own build, so this is a known category of gap, not a new one.
- **Node.js needs a book-listed patch the tarball fetch never pulled**:
  `node-v22.22.0-python_build_fix-1.patch` (Python 3.14 compat), listed as a `Required
  patch` on the book page and in the BLFS wget-list, just not tracked by
  `packages/base.py`'s single-tarball model. Fetched from
  `linuxfromscratch.org/patches/blfs/13.0/`, no MD5 published for patches on this page so
  none to check against.
- **Git needs a second tarball for its man pages**, `git-manpages-2.53.0.tar.xz` --
  same one-tarball-per-step gap as the Node.js patch. No MD5 published for it either (the
  book only lists one for the primary git tarball); verified with `xz -t` instead.
- **`blfs-sudo`'s shared override assumes the `john` user already exists.** Book's own
  text has no `usermod` line at all -- `recipes/blfs-overrides.json`'s decision for this
  page adds `usermod -aG wheel john`, written when server already had a live `john`
  account from its own `hand(177, "adduser-john", ...)`, created far later in server's
  real history than `blfs-sudo`'s seq 15. server's real build order never actually
  exercised this dependency; laptop's byte-for-byte fresh build was the first to. Fixed by
  giving laptop its own `hand(14.5, "adduser-john", ...)` in `packages.py`, reusing the
  same portable shared recipe (`recipes/blfs-adduser-john.sh`) server's own step points
  at, positioned to run before `blfs-sudo` -- `packages.py` had to switch from plain
  `BASE + [...]` concatenation to `sorted(..., key=seq)`, since neither `extract-blfs.py`
  nor `build-plan.py` re-sort by seq themselves; a host can only interleave before an
  existing `BASE` step if its own list is actually kept in seq order, not just written
  that way. Not promoted into `BASE` itself: that would inject a new, never-run step into
  server's own live `--resume` queue, where `john` already exists with a populated home
  directory -- a change worth a deliberate decision on its own, not a side effect of
  fixing laptop.

All four BLFS-BASE tarball/patch fetches verified where the book publishes a checksum
(`make-ca`, `openssh`, `nodejs`, `libunistring`, `libidn2`, `libpsl`, `curl`, `wget`,
`git`, `cpio`, `sudo`, `iptables`, `which`, `libtasn1`, `p11-kit` -- 15/15 against
`blfs-staging/blfs-md5-base`), sanity-checked by archive-integrity where it doesn't
(`certdata.txt`'s content shape, `git-manpages`' `xz -t`, the Node.js patch's provenance
header).

18.93 build-hours total, 15.1G free. Node.js alone took 200 of those minutes -- by far the
slowest of the 17 BLFS steps.

Next: the Hyprland/Wayland/pipewire tiers, researched against `book/blfs-13.0/` as each is
reached, following `server`'s `HYPRLAND-PLAN.md` for sourcing policy (BLFS page first,
Arch's `extra` PKGBUILDs where BLFS has none) with Intel/`iris` substituted for
NVIDIA/`nouveau` and pipewire/`pipewire-pulse` substituted for PulseAudio.

## 2026-08-30 to 2026-08-31: Hyprland Tiers 1-4 -- build tooling through the GPU/GL stack

88/88 BLFS steps (17 `BASE` + 71 new), ~25.4 build-hours total. See
`hosts/laptop/HYPRLAND-PLAN.md` for the tier breakdown. Reused server's own real build of
this exact stack (commit `9a4021b`, before it was removed for X11) instead of
rediscovering every gap blind -- versions, hand-authored recipes, and known gotchas all
came from there, substituting Intel for NVIDIA where GPU-bound.

Verified working: `iris_dri.so` (OpenGL), `libvulkan_intel.so` + a real
`intel_icd.x86_64.json` ICD manifest (Vulkan/ANV) -- this GPU has both, unlike server's
Kepler card which never got real Vulkan.

Real gaps found running this for the first time on Intel rather than NVIDIA, each fixed as
a recorded decision:

- **Ordering, not content.** server's own seq numbers reflect when a step was added across
  several sessions, not a clean dependency order -- its `blfs-xorg-env` is seq 120, long
  after the seq-37 `util-macros` step that already needs `$XORG_PREFIX` set. Laptop's
  `packages.py` reorders (`xorg-env` first, the full legacy X11 lib set built upfront
  instead of discovered piecemeal) but reuses the same versions and recipe content
  throughout.
- **`vulkan-loader`'s undisclosed test suite.** Not auto-flagged by the testsuite
  classifier (a cmake reconfigure + `ninja test`, not the usual `make check` shape) --
  `cmake -D UPDATE_DEPS=ON` makes its own CMakeLists git-clone a private copy of
  Vulkan-Headers regardless of the system copy already built, failing outright with no
  network in the chroot. Unconditionally network-dependent on any offline build, not
  laptop-specific -- fixed in the shared override.
- **Mesa's Intel drivers hard-require `libclc`.** `gallium-drivers=iris` and
  `vulkan-drivers=intel` unconditionally trigger Mesa's own `with_driver_using_cl`
  (iris/anv's shader compilation pipeline needs it, nothing to do with rusticl/OpenCL as a
  toggle) -- confirmed by reading mesa's actual `meson.build` after a first guess
  (`-D gallium-opencl=disabled`, an option name that doesn't even exist in this mesa
  version) failed. The real fix: `libclc` needs `spirv-llvm-translator`, which needs real
  LLVM+clang -- confirmed with the operator before committing to that ~4-hour, disk-heavy
  addition (LLVM alone: 233.9 min, the single longest step in this build so far). Also
  found `recipes/blfs-llvm.sh` was already hand-authored (deliberately skips the book's
  PAM-dependent 19-SBU test suite) but declared `book()` in laptop's first draft of
  `packages.py`, which would have let the next extraction overwrite it with a fresh
  auto-generated candidate that brings the test suite back -- caught before running the
  real extraction, fixed by matching server's actual `hand()` classification. Also found
  `spirv-llvm-translator`/`libclc` mislabeled `hand()` in server's own `packages.py` despite
  being real book pages -- corrected to `book()` for laptop.
- **Mesa's build-time Python deps.** `mako` and `pyyaml`, both required by Mesa's code
  generation scripts and neither in this BLFS mirror (`general/python-modules.html` covers
  dozens of modules on one page, doesn't fit the one-page-per-package model) -- server
  already had hand-authored recipes for both, reused verbatim, tarballs sourced from PyPI
  with sha256 verification.
- **`giflib`, `glib2` each needed book-listed patches** the single-tarball model doesn't
  track (glib2 needed two). Same category of gap as `make-ca`'s `certdata.txt` and
  Node.js's patch during the `BASE` build -- fetched from the book's own listed URLs,
  verified against the book's own published MD5s where given.

Confirmed, not assumed: `Hyprland` and the rest of the ecosystem (Tier 10) are still ahead
-- this checkpoint is build tooling through a working Intel OpenGL/Vulkan stack, not a
running compositor yet.

## 2026-08-31: Hyprland Tier 6 -- Rust toolchain + Cairo/Pango

100/100 BLFS steps, ~27.7 build-hours total, 13.8G free. `rustc`/`cargo` confirmed working
and linked against the system LLVM, not a bundled copy -- see below.

- **Rust links the system LLVM, not a bundled copy** (host override,
  `hosts/laptop/blfs-overrides.json`'s `bootstrap.toml`) -- the book's own documented
  config for when LLVM is present as a Recommended dependency (built with
  `LLVM_LINK_LLVM_DYLIB=ON` specifically for this, Tier 4). server's own recipe omits this
  because it deliberately skipped building standalone LLVM the first time it built Rust
  (before mesa's `libclc` forced the issue here) and let Rust bundle its own copy instead.
  Not a laptop-specific tweak -- the book's own text, just the branch server's history
  never took.
- **Rust's stage0 bootstrap needs live DNS the chroot doesn't have by default** -- the
  book says outright "you must have an internet connection to build this package," but
  `/etc/resolv.conf` is a symlink to systemd-resolved's stub, which doesn't exist without
  a running resolved. Same fix as the already-shared `blfs-claude-code` recipe (swap in
  real public resolvers for the duration of the build, restore via an EXIT trap). Needed
  by four packages in this one tier (`rust`, `cargo-c`, `cbindgen`, `librsvg`) -- promoted
  straight to the shared override file rather than laptop's own, since by that point it was
  obviously a repo-wide characteristic, not hardware-bound.
- **A near-miss worth recording**: `recipes/blfs-overrides.json` already had real,
  in-use entries for `blfs-rust` and `blfs-librsvg` from server's own earlier build (block
  1/2 LLVM+build-command decisions, and librsvg's `-D pixbuf-loader=enabled` fix). Adding
  the DNS wrapper as a *new* top-level key with the same name created a duplicate JSON key
  in the same file -- valid JSON, but Python's parser silently keeps only the last
  occurrence, which discarded the DNS fix without any error. Caught by checking the actual
  generated recipe against what was expected, not by trusting the edit succeeded. Fixed by
  merging into the real entries instead of leaving a shadow copy; would have been a fully
  silent failure otherwise, only surfacing as an unexplained "Could not resolve host" three
  packages and however-many-dollars-of-compute later.
- **`libjpeg-turbo` was ordered after `gdk-pixbuf` in this session's own first draft of
  `packages.py`**, not a book gap -- `gdk-pixbuf` hard-requires it and failed outright.
  Caught and reordered before either step had completed, so no history was actually lost
  by renumbering.

Rust itself: 100.4 minutes -- long, but well under the book's worst-case both because
linking system LLVM skips rebuilding it and because the operator's disk-risk sign-off
turned out cheap in practice, same pattern as LLVM itself.

Next: Tier 8 (input/session -- `libinput`, `seatd`), Tier 9 (XWayland), Tier 10 (the
Hyprland ecosystem itself), then pipewire.

## 2026-08-31: Hyprland Tiers 8-10 -- input/session, XWayland, the compositor itself

129/129 BLFS steps, ~29 build-hours total, 13.3G free. `Hyprland --help` runs clean,
`ldd` shows no missing libraries -- matches server's own verification exactly (a real
interactive session needs the physical console, can't be exercised from this
SSH-driven build). All 22 hand-authored Hyprland-ecosystem recipes reused verbatim from
server's proven build (commit `9a4021b`); every defect below is either an ordering
mistake in laptop's own first-draft `packages.py` or a real environment difference
(GLVND, undetected test suites, an unavailable glaze version) -- none needed
rediscovering what server already solved.

- **Two ordering bugs in this session's own draft**, not book/recipe gaps:
  `libjpeg-turbo` was listed after `gdk-pixbuf` (which requires it) in the Tier 6 pass,
  and `libevdev` was listed after `libwacom` (same). Both caught before the later step
  had completed and fixed by inserting the dependency earlier, not by renumbering
  anything that had already run.
- **`lua5.4` needs three files that aren't part of upstream Lua's tarball at all**:
  `liblua.so.patch`, `paths.patch`, `lua.pc` -- all from Arch's own `lua54` package
  sources, not lua.org. `lua5.5` needed a fourth (`liblua55.so.patch`, version-specific
  content) from Arch's `lua` package, which now tracks 5.5.x. All fetched from
  `gitlab.archlinux.org`, sha256-verified against the PKGBUILDs' own checksums.
- **`libei` and `xwayland` both had undetected test-suite blocks**, same class of gap
  as `vulkan-loader`'s in Tier 4 -- neither matches the classifier's usual `make check`
  shape (`meson configure -D tests=enabled && ninja test` for libei; a multi-step
  git-clone-piglit-and-weston block for xwayland), so both slipped through enabled and
  failed on missing test infra (`munit`, `xkbcomp`). Dropped in the shared override,
  since both are unconditional characteristics of building these pages without their
  optional test dependencies -- true of any host, not laptop-specific.
- **The `libglvnd=disabled` call from Tier 4 didn't survive contact with the real
  ecosystem** -- reversed here. `aquamarine`'s CMakeLists links against
  `OpenGL::OpenGL`, the GLVND-specific target CMake's `FindOpenGL` only creates when a
  real `libOpenGL.so` (GLVND's dispatch library) is present, independent of how many GPU
  vendors are actually installed. The original reasoning ("single vendor, nothing to
  dispatch between") was true but irrelevant -- GLVND has become the assumed baseline
  for this class of package, not an optional multi-vendor extra. Fixed by building
  `libglvnd` (server's own portable recipe) and rebuilding mesa with `glvnd=enabled`;
  the mesa rebuild cost ~20 minutes, not a big deal in practice. `libepoxy` (built after
  mesa, no GLVND-target dependency of its own) didn't need a rebuild.
- **Hyprland's `find_package(glaze 7...<8 QUIET)` rejects the system glaze (8.1.0)**,
  needed as-is by `hyprtoolkit`/`hyprland-guiutils` which already linked against it
  successfully -- downgrading system glaze would have broken those. Hyprland's own
  CMakeLists already anticipates exactly this case: on a `find_package` miss it
  `FetchContent`-clones its own pinned glaze v7.2.0, vendored just for its own build.
  This is a designed fallback, not a bug -- fixed by giving it the same DNS workaround
  every Rust/Cargo package in this build already needed (edited directly into the
  hand-authored recipe, not an override, since hand() files are meant to be edited).
- **The GCC 15.2 / libstdc++ `std::ranges::starts_with` gap server already found and
  documented as "expected to reproduce identically"** did reproduce identically --
  but the proactive patch was never actually written into the recipe the first time
  around, only promised. Applied now: `truthy()` in `MiscFunctions.cpp` materializes the
  lowercased view into a real `std::string` and uses the C++20 `std::string::starts_with`
  member function instead of the unimplemented C++23 range algorithm. The recipe now
  asserts the patch actually applied (`grep -q ... || exit 1`) rather than silently
  building unpatched source if the upstream file ever changes shape.

Next: pipewire + wireplumber (small, explicitly requested), then a deliberate stop --
GTK3, PulseAudio, the media codec tier, mpv, ffmpeg, and Firefox are a separate later
phase per the operator's standing instruction not to build everything at once.

## 2026-08-31: Tier 11 -- pipewire, closing out the planned Hyprland stack

132/132 BLFS steps, ~29.17 build-hours total, 13.3G free. All three recipes
(`pciutils`, `pipewire`, `wireplumber`) reused verbatim from server -- real BLFS pages,
mislabeled `hand()` there like `spirv-llvm-translator`/`libclc` in Tier 4, kept as
`hand()` here too since the content is portable with no GPU/host-specific tuning to lose
by not re-deriving from the book.

No real defects this time -- the one thing worth recording is a decision, not a fix:
confirmed by reading `multimedia/pipewire.html` directly before building anything that
PulseAudio is only "Recommended" on pipewire's own page for migration/coexistence, not a
build requirement -- `pipewire-pulse` (the actual PulseAudio-compatible service) builds
and is present (`/usr/bin/pipewire-pulse`) without real PulseAudio installed at all,
matching the operator's pipewire-not-pulseaudio instruction with zero build-time cost or
workaround needed.

`pipewire --version`, `wireplumber --version` both confirmed working (1.6.0 / 0.5.13).

**This closes out the plan in `HYPRLAND-PLAN.md` as originally scoped**: build tooling
through a working Intel GPU stack, the Rust/Cairo/Pango chain, input/session management,
XWayland, the full Hyprland ecosystem, and pipewire audio. `hyprctl`/`Hyprland` binaries
exist and load cleanly; an actual interactive session (Hyprland launched at the physical
console, with a `seatd`/session setup verified end-to-end, audio actually producing sound)
is still unverified -- this has been an entirely SSH-driven, non-interactive build, same
limitation server had at the equivalent point in its own history.

Deliberately not built, per the operator's standing instruction: GTK3, PulseAudio itself,
the media codec tier, mpv, ffmpeg, LLVM+clang's Firefox-specific rebuild, and Firefox.
Also not done yet: archiving this tree (`bin/lfs-archive --tree --final`) and the USB
deploy to `nvme0n1p1` -- the whole reason this build has lived in a chroot inside the repo
rather than a real partition from the start (see the 2026-08-28 disk-space decision,
top of this file).

## 2026-08-31: Tier 11 -- GTK3 + audio codec prerequisites

142/142 BLFS steps, ~29.56 build-hours total, 13.1G free. Clean run, no failures --
`libogg`, `flac`, `opus`, `libvorbis`, `libsndfile`, `alsa-lib` (+ its `alsa-ucm-conf`
recommended-file secondary download), `speex` (+ its required `speexdsp` second
tarball), `gsettings-desktop-schemas`, `at-spi2-core`, `gtk3` -- all real BLFS pages,
both secondary-tarball cases already handled correctly by the book's own recipe text
(no override needed, unlike `make-ca`/`glib2`/Node.js earlier).

PulseAudio deliberately excluded from this tier: confirmed by reading `x/gtk3.html`
directly that GTK3's own Required list is at-spi2-core/gdk-pixbuf/libepoxy/Pango only,
no PulseAudio at all. server bundled PulseAudio into the same wave because mpv/Firefox
need it, not GTK3 -- both still out of scope, so PulseAudio stays deferred until
whichever of them is actually reached.

Continuing directly into Tier 12 (media codec libraries) at the operator's instruction
to keep building.

## 2026-08-31: Tier 12 -- media codec libraries

156/156 BLFS steps, ~30.3 build-hours total, 13.0G free. Clean run, no failures --
`nasm`, `libusb`, `dav1d`, `libaom` (+ its `nasm3` patch), `libvpx` (+ its security-fix
patch), `x264`, `x265`, `lame`, `libass`, `svt-av1`, `fdk-aac`, `libva` (VAAPI --
meaningful on this GPU via mesa's iris driver, unlike server which only ever had VDPAU),
`sdl3`, `sdl2-compat`. Both patches (`libaom-3.13.1-nasm3-1.patch`,
`libvpx-1.16.0-security_fix-1.patch`) fetched from the book's own listed URLs.

Next: ffmpeg + mpv (Tiers 13-14), checking first whether either genuinely hard-requires
PulseAudio or accepts pipewire-pulse the same way pipewire's own page did.

## 2026-08-31: Tiers 13-14 -- FFmpeg + mpv, no PulseAudio needed

163/163 BLFS steps, ~30.73 build-hours total, 12.8G free. Confirmed working:
`ffmpeg -hwaccels` reports real `vaapi`/`vulkan`/`drm` (Intel hardware acceleration,
something server's Kepler card never had for the codecs that matter here); `mpv`'s
`ldd` shows it linked directly against `libpipewire-0.3.so`, no PulseAudio anywhere in
its dependency chain.

- **PulseAudio confirmed unnecessary for both**, verified before building rather than
  assumed: FFmpeg's own book page lists it Optional (not Required); mpv's book prose
  lists it Required, but the book's own `meson setup` command passes no explicit
  `-D pulse=`/`-D alsa=` flags at all -- both are meson `auto` features that silently
  skip if absent. `alsa-lib` (Tier 11) and `pipewire` (Tier 11, also a real "Optional
  Audio Output Driver" on mpv's own dependency list, not just the pulse-compat layer)
  gave mpv working audio with zero build-time cost, matching the pipewire-not-
  PulseAudio instruction for the third time this build (pipewire itself, GTK3, and now
  ffmpeg/mpv all avoided it once actually checked against the book text).
- **`libplacebo` needs `glad`** (a Python OpenGL-header generator), undocumented on
  libplacebo's own page -- another real BLFS page server mislabeled `hand()`
  (`general/glad.html`), corrected to `book()` here, matching the
  `spirv-llvm-translator`/`libclc`/`pciutils`/`pipewire`/`wireplumber` pattern.
- **FFmpeg's own recipe was 7/11 blocks of unwanted optional work**, none auto-flagged:
  PDF/PostScript docs (`texi2pdf`/`dvips`, texlive not installed), a Doxygen API-doc
  rebuild, both docs' install steps, and the ~1GB-download 5200-test FATE suite
  (rsync-based, rsync not installed either). All dropped via shared override -- true of
  any host without texlive/doxygen/rsync installed, not laptop-specific.
- **`mpv` needs `libXpresent`** (X11 Present extension, tear-free presentation),
  undocumented on mpv's own page (which only lists generic "Xorg Libraries") -- same
  class of gap as `libxscrnsaver` for SDL3 back in Tier 12. Server's own portable
  recipe, Arch's `libxpresent` PKGBUILD as reference, reused as-is.

This closes out the media stack. Only Firefox remains from the originally-deferred
list (GTK3, media codecs, mpv, ffmpeg are now all done; PulseAudio itself never needed
building at all).

## 2026-08-31: `bin/lfsbuild` false-positive bug found and fixed mid-Firefox-tier

`blfs-libnotify` (step 154, first of the Firefox dependency chain) reported `OK` with a
0-file manifest. The log showed a real failure: `meson setup` rejecting a missing `gtk4`
dependency (`../meson.build:50:10: ERROR: Dependency "gtk4" not found`) -- nothing was
built or installed, yet the driver recorded exit 0 and moved on.

Root cause is in `bin/lfsbuild` itself, not the recipe: bash's `set -e` does not abort on
the failure of a command that is not the last member of an `&&`/`||` list, and the book's
own recipes are written almost entirely as `configure && build` / `build && install`
chains. Traced byte-for-byte against the actual staged script and confirmed with a
minimal bash reproduction. Full incident and the fix's exact scope/limitation are in
`PRACTICES.md` ("`lfsbuild` itself can under-report a failure"), since this is
project-wide infrastructure that affects `server` too, not something specific to this
host.

Fixed in `build_script()`: the driver now captures the recipe's exit status immediately
after it runs and exits on failure before reaching manifest capture, instead of always
falling through to it. Verified against both the real libnotify failure shape and a
normal success shape before trusting it.

A sweep of every `hosts/*/manifests/*.txt` on this host for 0-line files, done before
trusting anything else already marked complete, found only `blfs-libnotify.txt` (this
bug) and `blfs-glaze.txt` (Tier 8-10, a separate manifest-capture anomaly -- its own log
shows real, successful file installation, so it is not a `set -e` case; not yet
investigated further). No other step among the 163 completed so far showed the same
signature. This does not rule out a step that partially installed files before an
exempted failure, since a nonzero-but-wrong manifest count is indistinguishable from a
correct one under this check.

`libnotify`'s own failure: its `meson.build` makes `gtk4` a hard dependency whenever
`tests=true` (the default), which the book's own configure line never disables. Fixed
with a shared override adding `-D tests=false -D introspection=disabled` (introspection
being a required, not auto, feature by default, and gobject-introspection is not part of
this build either) and dropping the optional gi-docgen API-doc block. Neither is
laptop-specific -- true of any host that has not built a full GNOME desktop ahead of
libnotify.

Rerunning uncovered a second, unrelated problem: a resumed `lfsbuild --resume` had
actually been running in the background since before this fix even started (from a
prior turn in this same session), and had already moved past the corrupted `libnotify`
state to `nss`, where it hit a real, separate failure -- `nss`'s test suite (block 1,
not flagged optional by the extractor for the same classifier-gap reason as
vulkan-loader/libei/xwayland/ffmpeg) failed 564-569 of its ~49,000 tests and exited
after ~21 minutes. A second `--resume` was started without checking for the first,
producing a several-minute window where two processes both operated on
`/sources/nss-3.120.1` in the same chroot tree. The first process exited on its own by
the time this was noticed; its Python driver was killed, but the orphaned root `sudo
chroot ... bash blfs-nss.sh` underneath a *second*, redundant invocation kept running
unsupervised (no permission to `sudo kill` it under the scoped sudoers rule) until it
finished naturally. Nothing was trusted from either run: `libnotify` was force-rerun
individually (`--only blfs-libnotify --force`, confirmed 7 real files installed) before
resuming the rest of the chain, and `nss`'s test suite got its own drop override (shared
-- true of any host not wanting to run a suite the book's own text already warns "fails
to spin down test servers... leads to an infinite loop") alongside a second drop for
block 3's p11-kit trust-module symlink (p11-kit is not part of this build, so the link
target does not exist). Lesson: check `ps` for a running `lfsbuild` before starting
another one -- state files do not prevent two live processes from both claiming the same
next step.

`nss` then genuinely succeeded under the fixed driver and corrected recipe: 280 files,
11.5 minutes (vs. the prior run's 20.9-minute test-suite failure). `libevent` hit its
own real, separate gap next -- `doxygen: command not found` -- an optional API-doc block
(book's own "If you have Doxygen installed and wish to build API documentation, issue:")
that the extractor does not auto-flag by design (prose-based optionality has caused real
breakage before, see `PRACTICES.md`). Dropped both the doc-build block and its
dependent doc-install block via shared override; doxygen is not part of this build.
`libevent` then installed 57 files cleanly.

`firefox` itself then failed immediately, before its recipe ever ran: `rm: refusing to
remove '.' or '..' directory: skipping '.'`. A second, distinct `bin/lfsbuild` bug, not
the `set -e` one -- `srcdir_of()` takes the first entry of `tar -tf` as the tarball's
top-level directory, and Firefox's own tarball lists an explicit `./` root marker as its
very first entry (confirmed with `tar -tf` directly), so `srcdir_of()` returned `.` and
the driver's own cleanup step ran `rm -rf "."`. Fixed by skipping a leading `.` entry the
same way the function already skips an empty one. Verified against the real tarball
before resuming: `srcdir_of("firefox-140.8.0esr.source.tar.xz")` now correctly returns
`firefox-140.8.0` (the real in-tarball name -- note it drops both `esr` and `.source`
from the download filename, confirming the book's own instinct to read this from the
tarball rather than infer it from the name). Full incident in `PRACTICES.md`.

Firefox is now building under both fixes. It is the last step of this tier and one of
the largest packages in the entire build; expect this to take hours.

Firefox's real second failure was `libpulse` -- its own configure treats PulseAudio as
required unless told otherwise. Fixed with a shared override uncommenting the book's
own pre-written `--enable-audio-backends=alsa` mozconfig line (PulseAudio was never
built anywhere in this project; pipewire + pipewire-pulse covers every other package).

Before the retry, a disk-space cleanup pass (requested directly, freeing space after
the failed attempt's partial build ate into the remaining headroom) went badly wrong: a
blanket `strip --strip-debug` across every unstripped file in `/usr/lib` hit
`libbfd-2.46.0.20260210.so` -- binutils' own internal library -- in place, truncating
it to zero bytes and breaking `ld`/`as`/`ar`/`strip` chroot-wide. The book's own
`ch08-stripping` step handles this exact library (and a short list of others) specially
for exactly this reason (copy, strip the copy, atomic install), which this ad hoc pass
did not replicate. `/tools`, the chapter 5/6 rescue toolchain, was already long gone.
Recovery: built a throwaway binutils on the host from this project's own tarball,
verified its binaries run correctly inside the chroot despite being host-glibc-linked,
used them as temporary `/usr/bin` replacements (kept as `.BROKEN` backups until
verified), then force-reran `ch08-binutils` to properly reinstall a correct, natively
built binutils -- 352 files, 15.1 minutes, fully verified afterward (real compile+link
test) before removing every temporary file. Full incident in `PRACTICES.md` ("Stripping
a live shared library in place can zero it out").

That same investigation surfaced a second `bin/lfsbuild` gap: a *correct* `-e` abort
mid-recipe (Firefox's own `./mach build` failing, not the earlier exempted-failure bug)
also skipped the driver's cleanup step, since it sat as plain sequential lines after the
recipe in the same script -- leaving Firefox's 4.1G partial source tree behind, which is
what caused the disk pressure the ad hoc strip pass above was trying to relieve in the
first place. Fixed by running the recipe as a genuine child process
(`bash recipe.sh || RECIPE_RC=$?`) instead of splicing it inline, so cleanup always
runs regardless of where a failure occurs. Full incident, and why the first fix wasn't
enough, in `PRACTICES.md`.

Firefox's third real failure was `libXdamage` -- a combined X11 pkg-config check
(`x11 xcb ... xdamage xfixes xi`) failing on that one library alone. Never previously
needed by anything else in this build (X11-legacy libs came in for XWayland/mpv, none
pulled this one in transitively). Server hit the exact same gap building its own
Firefox and already had a hand-authored recipe recorded (`recipes/blfs-libxdamage.sh`,
present on disk though never added to `server/packages.py`'s git history in a form
`git show` could find directly -- reused as-is regardless, config-only Xorg-library
build). Added as `hand(159.5, ...)`, tarball fetched fresh from x.org's own individual
lib mirror (not previously staged anywhere in this project).

With that added, the full remaining chain succeeded: `libxdamage` (6 files, 0.1 min),
then **Firefox itself: 197 minutes, 25 files, genuinely built and installed.** Disk
bottomed out at 4.8G free during the build (auto-cleaned back to 12G by the driver's
now-correctly-running cleanup step immediately after).

This completes every step of the originally planned build: LFS chapters 4-11, and every
BLFS tier from the GPU stack through Hyprland/pipewire/GTK3/media codecs/ffmpeg+mpv to
Firefox. 171/171 BLFS steps.

## 2026-09-01: cryptsetup, sshfs, wireguard-tools (requested, not part of the desktop plan)

179/179 BLFS steps. Server had already built this exact chain (disk encryption, remote
filesystem mounts, VPN) for its own extended scope -- versions and recipes reused
directly rather than rediscovered: `libaio-0.3.113` (LVM2's dependency; book's own
download URL is dead, fetched from `codeberg.org/jmoyer/libaio` instead, same fix
server already found), `json-c-0.18`, `popt-1.19`, `lvm2-2.03.38`, `cryptsetup-2.8.4`,
and the hand-authored `wireguard-tools-1.0.20260223` (no BLFS page covers it; the
kernel module has been in-tree since Linux 5.6, this is only the userspace CLI).

`fuse-3.18.1` and `sshfs-3.7.5` were genuinely new to this project (server never built
them) and needed real review: `fuse`'s optional Doxygen-doc and pytest-test blocks
dropped (same doc/test-tool pattern as every other package in this build), and
`sshfs`'s blocks 2-3 turned out to be literal usage-example commands from the book's
"Using Sshfs" section (`sshfs example.com:/home/userid ~/examplepath`) rather than
install steps -- would have tried to actually SSH to a nonexistent host during the
build. Both fixed via shared override, true of any host, not laptop-specific.

Kernel needs `FUSE_FS`/`CUSE` for sshfs to actually mount anything at runtime -- added
to the shared `bin/kernel-config-base.sh` (generic feature, benefits any host) but not
yet rebuilt into laptop's running kernel config, batched with cryptsetup's own
already-satisfied `DM_CRYPT`/`WIREGUARD`/crypto options for the next kernel rebuild
before deploy, matching how `server` batched its own equivalent additions. All three
target tools build and run correctly in the chroot (`cryptsetup --version`,
`wg --version`, `fusermount3` with its setuid bit correctly applied) -- verified before
considering this done, not just assumed from a clean build.

## 2026-09-01: kernel rebuilt for FUSE_FS/CUSE

First `--force` rerun of `ch10-kernel` (32.1 min) silently did *not* pick up the
`FUSE_FS`/`CUSE` addition: `bin/kernel-config-base.sh` is staged into `$LFS/sources`
manually, once, per `BOOTSTRAP.md` (the host script sources it by relative path at
build time) -- not automatically re-copied on every build -- and the staged copy inside
the chroot was still the one from 2026-08-30, before this session's edit. `make
olddefconfig` (in `kernel_config_finish()`) then had nothing new to apply, and since
`FUSE_FS` isn't on the boot-path gate's checklist, nothing caught the miss. Re-copied
the current `bin/kernel-config-base.sh` into `$LFS/sources` and reran: second attempt
(31.9 min) confirmed `CONFIG_FUSE_FS=m` and `CONFIG_CUSE=m` both present in
`/boot/config-6.18.10`, alongside the already-correct `DM_CRYPT`/`WIREGUARD`/crypto
options from the original build. Worth remembering for any future kernel-config-base.sh
edit: it must be manually restaged before the next `ch10-kernel --force`, the same as
the first time through chapter 10.

## 2026-09-01: `glaze`'s manifest anomaly root-caused -- and turned out to affect 34 packages

`glaze`'s manifest capture used `find -newer <stamp>` (mtime), and its header-only
CMake install preserved the source tarball's original file timestamps (2026-08-17)
instead of refreshing them, so every one of its 298 files looked "older" than the
build step that installed them -- 0 recorded, despite a genuinely correct install.

A sweep of every completed step's install log against its manifest (comparing CMake's
own `-- Installing:` line count to the recorded file count) found this was not
glaze-specific: **34 packages** were affected, several severely --
`cmake` (4 of 4011 recorded), `llvm` (477 of ~3700), `hyprland` (105 of ~520),
`sdl2-compat` (17 of ~110), `abseil-cpp` (395 of ~790). All silently invisible to
`lfsmaint`'s ownership tracking despite being correctly installed. Full incident and
the general lesson in `PRACTICES.md` ("The package database trusted mtime, and CMake
doesn't always update it").

Fixed in `bin/lfsbuild`: manifest capture now uses `-cnewer` (ctime) instead of
`-newer` (mtime) -- ctime cannot be inherited from a source tree, so this failure mode
cannot recur. All 34 already-built packages' manifests were reconstructed from their
own install logs and backfilled (one, `libzip`, needed a second fix: its man pages had
been compressed to `.gz` by an unrelated earlier cleanup pass in this same session,
*after* its log was written, so the literal logged paths no longer existed -- checking
for a `.gz` sibling resolved it). Verified the backfill introduced no false positives:
every remaining log-vs-manifest gap, spot-checked across several packages, traced to
either a directory entry (correctly excluded) or an already-cleaned-up build-tree test
path under `/sources/...` (never a real installed file to begin with).

## 2026-09-01: carried over identity/locale config from the live host

Requested: scan the live host's `/etc` for currently-used config worth carrying into
the target build. Chapter 9's `ch09-network`/`ch09-locale`/`ch09-console` steps were
still on the book's own placeholders (`echo "lfs" > /etc/hostname`, a loopback-only
`/etc/hosts`, `LANG=en_US.UTF-8`, `KEYMAP=de-latin1`) -- none had been host-reviewed
yet. Timezone was already correct (`ch08-glibc` already points `/etc/localtime` at
America/Chicago, matching the live host exactly).

Added host-specific overrides matching the live host's actual, currently-in-effect
config (direct reads, not retyped from memory): hostname `laptop`, the real `/etc/hosts`
LAN map plus the existing WireGuard mesh (10.0.0.0/24, directly relevant now that
wireguard-tools is in this build), `LANG=C.UTF8` (the live host's exact value, no
hyphen -- not a typo, that's what's actually configured and working), and console
keymap `en`. All three steps force-rerun and verified against the actual chroot
filesystem afterward.

Deliberately not carried over, pending a decision (asked separately): NetworkManager
(not in the current plan at all, but is what actually provides WiFi on the live host --
without it or an equivalent, the deployed laptop has no way onto WiFi), the 14 saved
WiFi profiles in `/etc/NetworkManager/system-connections/` (sensitive -- network names
reveal travel history and may carry credentials), Tailscale (installed and actively
managing DNS/resolv.conf on the live host, not in the plan), and two hardware-specific
daemons found in `/etc/modprobe.d`/`/etc/thermald` that aren't part of the plan either:
`evdi` (DisplayLink docking-station external-display support) and `thermald` (ThinkPad
thermal management).

## 2026-09-01: NetworkManager, Tailscale, and thermald -- the live host's actual network/thermal stack

Follow-on from the `/etc` scan above: the live host's own NetworkManager (active,
managing real WiFi), Tailscale (active, managing DNS), and thermald (ThinkPad thermal
tuning) were all missing from this build's plan entirely. Added the full dependency
chain in order: `go` (needed to build tailscale) -> `tailscale`; `duktape` -> `polkit`;
`libnl` -> `wpa_supplicant`; `libndp` -> `NetworkManager`; `upower` -> `thermald`.
`libgudev`/`libusb` (upower's own deps) were already present from Tier 8-10.

`polkit` built **without** its Recommended PAM support -- PAM is not Required (only
duktape+GLib are), and the book's own PAM page warns that installing Linux-PAM requires
Shadow and Systemd to be reinstalled/reconfigured afterward for it to take effect, a
much larger and riskier change than "add WiFi" on a system whose login/su/sudo already
work. `-D authfw=shadow` (a real, supported meson option, read from meson_options.txt,
not guessed) used instead.

**Real gaps found and fixed, none guessed ahead of time:**
- `polkit`: needed `-D authfw=shadow` (pam not installed), `-D introspection=false`
  (gobject-introspection not installed, same libnotify-class boolean-not-auto option),
  `-D man=false` (xsltproc not installed). Also a genuine idempotency bug in the book's
  own block 0: `useradd` (unlike the `groupadd -f` beside it) fails outright on a
  second run once the user already exists -- hit for real when this step's first
  attempt got partway through before failing on the pam issue. Fixed with the same
  check-first guard used elsewhere in this build.
- `wpa_supplicant`: blocks 6-8 dropped -- a literal `SSID` placeholder piped through
  the interactive `wpa_passphrase` (would hang an unattended build), and two
  `systemctl start/enable wpa_supplicant@wlan0` calls that would fight NetworkManager
  for control of the wifi interface (NetworkManager spawns its own wpa_supplicant
  instances via D-Bus, which is what block 1's `CONFIG_CTRL_IFACE_DBUS` additions are
  for).
- `NetworkManager`: `-D nmtui=false` (libnewt not installed, the book's own error names
  the fix directly), `-D introspection=false` -- which also fixed a second, initially
  unrelated-looking symptom (`ninja install` failing on `xsltproc` and leaving
  `/usr/share/doc/NetworkManager` never created, so the doc-install block had nothing
  to copy) traced to `man/meson.build`'s own gate, `if enable_introspection and
  (enable_man or enable_docs)`. Block 8's `<username>` placeholder replaced with `john`
  (this project's own already-existing user).
- **Architectural conflict, not just a build failure**: `ch09-network` was already
  configuring `systemd-networkd` to manage all `en*`/`eth*` interfaces via DHCP -- the
  book's own NetworkManager page warns explicitly that this fights NetworkManager for
  interface ownership. Dropped that config block and flipped `ch09-network` block 0
  from drop to enable (`systemctl disable systemd-networkd-wait-online`) -- the book's
  own text names this exact NetworkManager scenario, which just didn't apply before
  NetworkManager was in the plan. DNS is unaffected either way: NetworkManager runs
  with `dns=none`, so `/etc/resolv.conf` stays owned by systemd-resolved throughout.
- **Self-inflicted disk/manifest bug**: `go build`ing tailscale (no `vendor/` directory
  in its tarball, confirmed by inspection) downloaded ~1.7G of Go module cache into
  `$HOME/go` and `$HOME/.cache/go-build`, which the driver's own `-cnewer` manifest
  capture correctly-but-wrongly recorded as 16,629 "installed" files (they were freshly
  written during the step, so ctime-wise indistinguishable from real output) and which
  then blocked the next step on disk headroom. Fixed the shared `blfs-tailscale.sh` to
  clean up both cache directories at the end of the recipe, and backfilled the manifest
  down to the 4 files tailscale actually installs (`/usr/bin/tailscale`,
  `/usr/sbin/tailscaled`, its systemd unit, its defaults file).

`thermald` has no BLFS page at all -- hand-authored from `intel/thermal_daemon`
upstream (v2.5.12). Its release-tag source archive needed two patches to `autoreconf`
cleanly, both verified against the real extracted source (full `autoreconf -fi` run to
completion, then `./configure` smoke-tested) before trusting them: `AX_CHECK_COMPILE_FLAG`
(autoconf-archive, not installed, but the macro's own `m4_ifdef` guard meant a direct
`-std=c++11` assignment was a clean substitute) and `GTK_DOC_CHECK` (gtk-doc, not
installed, unconditional in configure.ac -- dropped the pure-API-doc `docs/` subdir
entirely; confirmed by inspection it holds no man pages, those live under `man/` and
install independently via `man5_MANS`/`man8_MANS`).

All new binaries spot-checked working in the chroot afterward: `nmcli --version`,
`tailscale --version`, `wpa_supplicant -v`, `pkexec --version`, `thermald --version`,
`/usr/libexec/upowerd` (no `--version` flag, but executes and parses its own args
correctly, confirming a real, correctly-linked binary).

189/189 BLFS steps.

## 2026-09-01: emacs, screen, and a real security pass -- SSH hardening, iptables at boot

Added `emacs-30.2` (needed `jansson`, `libtiff`, `gnutls` -- all its other Recommended
deps, harfbuzz/giflib/cairo/dbus/glib2/gtk3, were already present) and `screen-5.0.1`
(`--disable-pam`, no other deps). `emacs`'s own configure failed once on `libXpm` (old
X Pixmap support, mostly toolbar-icon cosmetics) not being installed -- the error
message named the fix directly, `--with-xpm=ifavailable`.

**Found a real, previously-unnoticed gap while wiring up the requested iptables-unit
step**: `sshd.service` was never actually enabled for this host at all. `openssh` has
been installed since `BASE`, but nothing had ever run the BLFS systemd-units package's
`make install-sshd` target -- this host has had no way to accept an SSH connection this
entire build. Added `sshd-unit` alongside `iptables-unit` (both hand-authored, no BLFS
page of their own, both pull from the same shared `blfs-systemd-units-20251204`
source package). `iptables` itself was already built as part of `BASE` with a real
personal-firewall script (policy DROP, loopback + established/related + explicit
inbound SSH allowed) reused directly from `server`'s own proven, already-reviewed
recipe -- `iptables-unit` is what actually wires that script to run at boot.

**SSH hardening (requested: no root login, no password login, no password for root):**
- `PermitRootLogin no` -- reverts a *shared* override that sets `yes`, which was a
  deliberate, explicitly-flagged bootstrap compromise for `server`'s original
  root-only situation (no other account existed yet at the time). Does not apply here:
  `john` has had full wheel/sudo access since `blfs-adduser-john` (seq 14.5), so there
  is no window where root-over-SSH is the only way in. Also simply the book's own
  unmodified default -- confirmed directly against the book HTML, not assumed.
- `PasswordAuthentication no` / `KbdInteractiveAuthentication no` -- previously dropped
  by the same shared override because no `authorized_keys` existed anywhere in this
  build. Fixed by carrying over `john`'s real, currently-in-use authorized_keys from
  the live host (2 keys, `pi-tv` and `pi-master-tv` -- public keys, safe to copy;
  private keys never left the live host) via a new host-specific hand recipe,
  `hosts/laptop/recipes/blfs-authorized-keys-john.sh`.
- **Real bug found applying this**: `sshd_config` is a persistent config file, and the
  book's own `>>` append is not idempotent across a `--force` rerun -- the first build
  (under the old shared `yes` override) had already appended `PermitRootLogin yes`;
  appending the new `no` on top left *both* lines in the file. sshd honors the first
  occurrence of a repeated directive, so the stale `yes` was silently winning even
  after the fix looked correct in the recipe. Caught by inspecting the actual built
  config, not assumed from a clean build log. Fixed the live file directly and made the
  override idempotent (`sed -i '/^PermitRootLogin /d'` before appending) so this can't
  recur on any future rerun.
- **Root**: `passwd -l root` (was a real, working `lfs-changeme` password from the
  book's own default) -- root is now reachable only via `sudo`, matching the request
  for "no password for root."
- **`john`**: unlocked with the same known-placeholder bootstrap password pattern
  root already used (`lfs-changeme`, requested directly) -- this is for local/console
  login and `su`/`sudo` prompts only; SSH itself stays key-only regardless of this
  account's password, so the two settings don't conflict.
- Both `blfs-adduser-john` and `blfs-openssh`'s block 0 (`polkit`'s own earlier
  precedent) needed the same idempotency fix: `useradd` is not safe to `--force` rerun
  once the account already exists. `blfs-adduser-john` hit this for real applying the
  password change -- fixed with the same check-first guard already used elsewhere.

All verified directly against the built chroot afterward, not assumed from clean
build logs: `sshd.service`/`iptables.service`/`NetworkManager.service` all
`enabled`; `sshd_config` has exactly one line each for the three directives above;
root's shadow entry is `!`-locked; john's shadow entry has a real password hash and
`groups john` shows `wheel`+`netdev`; `authorized_keys` has 2 real keys.

197/197 BLFS steps.

## 2026-09-01: /lfs-audit findings fixed, plus two serious self-inflicted incidents

Fixed everything from the `/lfs-audit` report except the SSH host keys (kept as-is per
request): removed the stale `/etc/systemd/network/10-dhcp.network` that was still
actively conflicting with NetworkManager (dropping a block from a recipe does not
retroactively delete a file an earlier run of that step already created -- the same
"recipe drop is not a retroactive undo" class of bug already in this file, now seen a
third way); cleaned up 423M of leftover `/root/.cargo` build cache; enabled
`thermald.service`; packaged and installed `lfsmaint` itself into the target (it was
never actually copied to `/usr/sbin`, so `lfsmaint-check.timer`/`cpufreq-governor.service`
-- both defined in `overlay/units/` since server's build -- had never been added to
laptop's plan at all); built the package database (307 packages, 101,583 files) and
ran `report`/`verify`/`orphans`/`advisories` for real, which surfaced a real gap in
`lfsmaint` itself (see below) and confirmed everything else was either expected noise
or already correctly explained by earlier work this session.

Fixed a real bug in `bin/lfsmaint verify` while at it: 9,633 of its "unexplained
missing" files were man/info pages this session's earlier disk-cleanup pass had
compressed to `.gz` after their manifest was written -- `verify` didn't know to check
for the renamed file. Added that check (mirrors the `-cnewer`-vs-`-newer` fix from
earlier today); down to 5 genuinely unexplained entries, all individually confirmed
benign (a root-only sudoers file `verify` itself can't read unprivileged, three stale
doc-manifest entries, and one symlink correctly removed by today's own NetworkManager
fix).

Also carried over the live host's full `~/.ssh` (all keys, `config`, `known_hosts`) into
`/home/john/.ssh` as requested, for immediate connectivity post-deploy -- a direct,
one-time file copy outside the recipe system, not committed to git (private key
material, unlike the earlier `authorized_keys`-only recipe which is public-key-only and
safe to track). Runtime-only `agent/` socket dir and a dangling dotfiles-repo symlink
excluded.

**Two serious incidents, both self-inflicted, while doing the requested strip pass:**

1. Repeated the exact `libbfd` mistake from `PRACTICES.md`'s own already-existing
   entry -- a blanket `strip --strip-debug` corrupted binutils' internal library
   again. Recovered with the same host-side rescue-binutils procedure as before
   (documented, reused directly).
2. Worse: the *fix* for that (an `ldd`-derived exclusion list) missed the dynamic
   loader itself, `/usr/lib/ld-linux-x86-64.so.2` -- `ldd` prints the interpreter line
   without the `=>` marker the exclusion list was built from. Stripping it in place
   broke every dynamically-linked program on the system, `bash` included, needing a
   full glibc rescue build on the host (two attempts -- the first used a throwaway
   `--prefix` that baked in the wrong default library search behavior) and a
   fully-static host-compiled copy tool to place the fix at all, since `sudo chroot
   ... bash -c` was itself unusable by that point.

Both fully recovered and verified (`ld`/`as`/`ar`/`strip`/`bash`/`gcc` all confirmed
working, a real compile+link+run test passed) without a full `ch08-glibc --force`
rebuild -- the rescue build used identical source, patches, and configure flags to the
real recipe, just skipped the (multi-hour, mandatory-per-the-book) test suite. Residual
risk is low but non-zero; a full `ch08-glibc --force` rebuild before final deploy is
cheap insurance worth doing when there's time for it. Full incident writeup, and the
revised non-negotiable stripping rule that should prevent a third occurrence, in
`PRACTICES.md`.

A third finding, discovered only after both incidents: the entire premise of the
2,942-file "not stripped" count was wrong. `file`'s classification checks for a
`.symtab`, which `--strip-debug` never removes by design -- only 16 of those 2,942
files had actual `.debug_info` to strip. Of those 16, the 4 binutils-internal ones
(`strip`, `libbfd`, `ld-linux-x86-64.so.2`, `libopcodes`) were deliberately left alone
this time (negligible savings, already recovered twice); the remaining 12 real
libraries were stripped using the unconditional atomic copy-strip-install pattern,
verified safe even against `/usr/bin/xargs` while it was the active process running
the loop. Man/info compression finished separately: man pages 2,435 -> 1,083
uncompressed remaining (all either symlinks or hardlinked/already-`.gz`-duplicated,
diminishing returns), info pages 18 -> 9 (same pattern).

Also fixed, smaller: `overlay/`, the deploy-time file tree, was not host-scoped despite
`hosts/server/overlay/` already existing as a convention (`grub.cfg`/`xorg.conf`/
`mpv.conf`) -- five of server's own X11/awesome dotfiles (`start-awesome.sh`,
`.xinitrc`, `awesome/rc.lua`, `picom.conf`, `alacritty.toml`) were sitting in the
*shared* `overlay/` instead, which would have installed the wrong desktop environment
onto laptop at deploy time had they never been noticed. Moved to
`hosts/server/overlay/` to match the existing convention; documented in `CLAUDE.md`'s
shared-or-host section so it doesn't happen again.

**Not yet done, a separate and much larger decision**: `lfsmaint advisories` (now
finally runnable) reports 85 LFS/BLFS security advisories affecting installed
packages, 54 of them Critical or High severity, spanning dozens of packages
(firefox, glibc, openssl, the kernel, vim, and many more). This is a real, large
security backlog, not something to fix inline with the audit's smaller infrastructure
items -- each advisory needs checking against the actual installed version (the tool's
own note: "an advisory names a package, not a version -- it may predate what you
have installed") before deciding whether it's even applicable, and remediating the
real ones would likely mean another build-tier's worth of work. Flagged for a
separate, explicit decision on scope and priority rather than started unilaterally.

## 2026-09-01: Claude Code, user-level install for john

Requested: install Claude Code via npm at the user level, not system-wide. Node.js was
already in `BASE` (seq 6). Hand-authored recipe runs `npm config set prefix
"$HOME/.npm-global"` as john (via `su - john`) before `npm install -g
@anthropic-ai/claude-code`, so every installed file lands under john's own home and
owned by john -- no root-owned system npm tree involved. Needed the same DNS fix as
every other live-fetch recipe in this build (npm reaching registry.npmjs.org). Added
`$HOME/.npm-global/bin` to john's own `.bashrc`, not a system-wide `/etc/profile.d`
file, matching the "user level" request specifically.

Verified for real, not just a clean build log: `su - john -c 'which claude; claude
--version'` resolves via `john`'s own login PATH and reports `2.1.258 (Claude Code)`;
install directory (`~/.npm-global`) confirmed owned by `john:john` throughout.

199/199 BLFS steps.

Next: decide on the advisories backlog above, spot-check that Hyprland/Firefox/mpv
actually run (this has all been chroot-only so far, no live session), rebuild the
kernel one more time if any further config changes land, then plan the archive
(`bin/lfs-archive --tree --final`) and USB deploy to `nvme0n1p1`/`p2`.

## 2026-09-01/02: Home directory backup, and the USB deploy image

Two separate deliverables, both prerequisites the operator called for before any
write to the internal disk: a backup of the *live host's* own home directory (so an
"old home" reference exists to selectively restore from after the new system is in
place), and a bootable USB carrying the laptop tree so far, ready to deploy from.

**Home directory backup.** `/home/john` (4.9GB) streamed directly to
`server:~/laptop_backup/home_backup.tar.zst` via `tar -C /home/john -cf - . | zstd -T4
-19 --long=30 -q | ssh server 'cat > ...'` -- no local staging copy, since root only
had 20GB free and the LUKS volume this repo lives on had 9.6GB. First attempt combined
manual `nohup ... &` backgrounding with the harness's own background-task tracking;
the outer wrapper returned (and was reported complete) the instant it launched the
pipeline, while the real `tar|zstd|ssh` chain kept running, detached and untracked, for
another ~30 minutes. Relaunching properly (backgrounded once, by the harness itself,
not by hand) left two independent pipelines racing to the same destination filename --
caught via `ps` before it did any damage: the second pipeline's `rm -f` had already
unlinked the first's target, so the two ended up writing to physically separate
inodes the whole time, never interleaving. Killed the stale first pipeline once
confirmed; the survivor finished clean (1.9GB compressed, 4.9GB uncompressed).
Verified, not just trusted: `zstd -t --long=30` on the full stream (clean), tar entry
count within the expected margin of live-filesystem churn during the capture window,
and a 7-file byte-for-byte spot check (sha256) spanning dotfiles, `.ssh/config`, a
Nextcloud log, an mbsync state file, a deeply nested config file, and two symlinks
(`.bashrc`, `.emacs.d/init.el`) resolved against their real targets.

**USB deploy image.** Same physical stick used for `server`'s own 2026-08-25 USB
deploy (confirmed via `lsblk`/`udevadm`: `ID_SERIAL=Lexar_USB_Flash_Drive_...F6934`,
matching partition sizes -- `sda1` 2.0G swap `LFSSWAP`, `sda2` 27.3G ext4 `LFSROOT`),
reused rather than repartitioned, per `hosts/server/BUILD-REPORT.md`'s own documented
"USB deployment" procedure. Sequence:

1. `bin/lfs-umount --host laptop` (fixed to resolve the tree at all -- see
   `PRACTICES.md`), then `bin/lfs-archive laptop-lfs-13.0-systemd.tar.zst --tree
   --final --host laptop` (also fixed, same `PRACTICES.md` entry) produced the
   deliverable: 1.6GB, 132632 entries, 23 setuid/setgid bits and 2595 hardlinks
   preserved, clean leak check (no `proc/`/`sys/`/`run`/`dev/pts` content), sha256
   `46eb0be9bb0fa18a3def09b4ca3d234872fc41a2717d18880e7610abf284fb74`.
2. `mkfs.ext4 -F -L LFSROOT /dev/sda2` + `mkswap -L LFSSWAP /dev/sda1` -- filesystem
   content only, the MBR partition table itself untouched (confirmed: `sda2`'s
   PARTUUID is still `219159d2-02`, identical to what `server`'s own grub.cfg
   recorded for this same disk signature).
3. Extracted onto `sda2` (`tar -p --numeric-owner --xattrs --acls --same-owner`) --
   5.3GB, ~40 minutes at USB-flash speed, matching `server`'s own documented
   "sequential fast, many-small-files slow" characteristic.
4. Bind-mounted `/dev`, `/dev/pts`, `/proc`, `/sys`, `/run` into the extracted tree,
   `chroot`'d in, ran `grub-install --target=i386-pc --recheck /dev/sda` using the
   stick's *own* GRUB (294 modules, `core.img` written into the post-MBR gap) --
   `/usr/sbin/grub-install`, not `/usr/bin` (first attempt used the wrong prefix).
5. Hand-wrote `/boot/grub/grub.cfg` for the stick's boot chain: `search --set=root
   --fs-uuid` against the fresh ext4 UUID (`781d8314-...`, changed by the reformat,
   unlike the PARTUUID), `root=PARTUUID=219159d2-02 rootwait` (no microcode initrd or
   hardware quirk flags -- this is Intel HD 520 / Conexant audio, confirmed clean by
   the hardware audit, not `server`'s NVIDIA/HDA situation).
6. Verified: `grub-script-check` clean, referenced kernel
   (`vmlinuz-6.18.10-lfs-13.0-systemd`) present, `umount -R` then `e2fsck -f -n
   /dev/sda2` clean (130402/1790544 files, 21% used).
7. The archive itself was *not* stashed inside the stick's own `/root` (`server`'s
   pattern) -- copied to `server:~/laptop_backup/laptop-lfs-13.0-systemd.tar.zst`
   instead (sha256 confirmed identical after transfer), reachable over the network
   once booted from the stick, same sourcing convention `BOOTSTRAP.md` already uses
   for fetching build sources from `server`. Avoided a second on-stick copy and the
   extra sudoers grant a `cp` step would have needed.

**Sudo, for all of the above.** None of it was covered by the build's existing
narrowly-scoped `NOPASSWD` rules (those cover the chroot-build pipeline specifically),
and this session's `sudo` has no TTY anywhere -- including the operator's own direct
attempt -- so no path existed to supply a password interactively. Resolved by adding
`/etc/sudoers.d/lfs-laptop-deploy`, a new drop-in scoped exactly to this sequence
(specific `umount`/`mount`/`mkfs`/`mkswap`/`chroot`/`e2fsck`/`tar` invocations pinned to
the exact tree path, script path, or confirmed USB device -- nothing broader), added by
the operator directly via `visudo` rather than by this session.

Deploy to the internal disk (`nvme0n1p1`/`p2`) itself has not happened yet -- this
entry covers preparation only. `bin/lfs-archive`'s own `--live` mode restore
instructions, and `BOOTSTRAP.md` section 5-6, are the reference for that step when it
happens.

## 2026-09-02: Repo clone onto the USB, for using Claude Code from the stick itself

`git clone` (local path, not the raw working tree -- avoids dragging along
gitignored bulk the USB's own root already *is*, `/lfs/` in particular) into
`/mnt/usb/home/john/agent-built-lfs`, 20MB, full history. `/home/john` inside the
extracted tree turned out already owned by uid/gid 1000 -- the same uid this host's
own `john` runs as -- so the clone needed no extra privilege beyond the existing
`mount /dev/sda2 /mnt/usb` grant. Booting the stick and running `claude` from
`~/agent-built-lfs` (Claude Code is already installed at the user level, per the
2026-09-01 entry above) gives a working session with the same tooling and context
this build has used throughout, without needing network access to fetch the repo
first.

## 2026-09-02: USB boot test -- wifi firmware never added, two network managers enabled

Booted `/mnt/usb` and found ethernet reported unreachable in `nmcli`, with `dmesg`
flagged as full of firmware/driver errors. Captured `dmesg.out` (940 lines) and
`lspci.out` at `/mnt/usb/home/john/` and read both in full rather than acting on the
symptom description alone -- they turned out to describe two unrelated problems.

**Wifi, not ethernet, is what the firmware errors are for.** Every one of the 15
`Direct firmware load ... failed` lines in `dmesg.out` is for `iwlwifi 0000:04:00.0`
(Intel Wireless 8260, trying `iwlwifi-8000C-36.ucode` down through `-22.ucode` before
giving up with "no suitable firmware found!"), plus one for `cfg80211`
(`regulatory.db`) and one for `i915` (`skl_dmc_ver1_27.bin`, DMC/runtime-power-management
firmware only -- display itself still works without it). `host.toml`'s own
`[hardware]` `wifi` line already said the 8260 "needs iwlwifi-8260 firmware blobs from
linux-firmware, a BLFS step" -- that step was simply never added to `packages.py`. The
wired NIC (Intel I219-LM, `e1000e`) is clean in the same dump: driver loads, MAC
`54:ee:75:9b:1d:af` assigned, renamed `eth0` -> `enp0s31f6` at t=20.6s, no firmware
requested or missing.

**The wired-unreachable symptom traced to `systemd-networkd` and `NetworkManager`
both being enabled at once.** `systemctl --root=/mnt/usb` showed
`NetworkManager.service`, `systemd-networkd.service`, and
`systemd-network-generator.service` all enabled under `multi-user.target.wants/`.
LFS 13.0-systemd ships `systemd-networkd` enabled by default -- it's what `server`
deliberately runs, with no NetworkManager at all. `laptop`'s own 2026-09-01 entry above
added NetworkManager to carry over the live host's real WiFi/connection state, but
never disabled the base image's `systemd-networkd` units, leaving two managers
eligible to own the same links. No `.network` file currently matches plain ethernet
explicitly (only the shipped `89-ethernet.network.example` does, and it's inactive),
so this wasn't a hard deadlock, but it's exactly the kind of unreviewed dual-ownership
that produces flapping/unreachable `nmcli` status.

Also requested during the diagnosis: `usbutils` (`lsusb`) for further hardware checks
-- wasn't installed on `/mnt/usb` at all, despite a BLFS-extracted recipe for it
already sitting at `recipes/blfs-usbutils.sh` from an earlier, unused extraction pass.

Fixed in `packages.py`, `seq` 189-192, next build:

- `linux-firmware-iwlwifi-8260` (189) and `linux-firmware-i915-dmc` (190) -- hand
  recipes, each fetching the one blob its device needs from
  `anduin.linuxfromscratch.org/BLFS/linux-firmware/` (confirmed present on the mirror
  before writing the URLs down), same narrow-fetch policy as `server`'s
  `linux-firmware-rtl-nic` (seq 172).
- `laptop-network-manager-only` (191) -- hand recipe, `systemctl disable
  systemd-networkd.service systemd-networkd.socket systemd-network-generator.service`,
  scoped to `laptop` only since `server` needs the opposite.
- `usbutils` (192) -- wired the existing extracted recipe in.

Not fixed: `regulatory.db` -- no `wireless-regdb` page exists in this BLFS book
mirror, and it only restricts the wifi channel/tx-power set rather than blocking
association, so it's deferred rather than sourced ad hoc.

**Run the same day.** `/mnt/crypt` had no headroom for `lfsbuild`'s 8GB build-step gate
(5.9GB free, 97% used) -- cleared by deleting `blfs-staging/*.tar.*` (861M of already-
gitignored, re-fetchable BLFS source downloads, not tracked or precious). All four
steps then ran cleanly against the chroot tree (`ch07-kernfs` needed a `--force` remount
of the virtual kernel filesystems first, since the tree had been unmounted since the
last session). The two firmware recipes needed the same `/etc/resolv.conf` swap the
`rust`/`go`/`tailscale`/`claude-code` recipes already use -- added directly to both
(they're `hand()` entries, safe to edit in place, no extractor drift). `usbutils-019
.tar.xz` wasn't staged in `lfs/sources` (BLFS sources aren't fetched by
`bin/fetch-sources.sh`, which only covers the 92 LFS-book sources) -- fetched directly
from the URL in `book/blfs-13.0/general/usbutils.html` and placed via the existing
`sudo chroot .../lfs *` grant (`cp` from world-writable `lfs/tmp/`, no new sudoers
needed). Rebuilt the tarball with `bin/lfs-archive --tree --final` (1.6G, leak check and
setuid/hardlink preservation both clean) and extracted it onto the still-mounted
`/mnt/usb`.

**Real gotcha, worth remembering:** `tar --extract` is not a mirror -- it only adds or
overwrites entries present in the archive, it never deletes a destination file that the
new archive no longer contains. The `laptop-network-manager-only` step deletes six
symlinks in the source tree, so the new tarball simply has no entries for them, and the
extract left the previous deploy's stale enabled-symlinks sitting on `/mnt/usb`
untouched (firmware and `usbutils`, being additions, extracted correctly). Caught by
re-checking `systemctl --root=/mnt/usb is-enabled` after the extract and finding
`systemd-networkd` still enabled; fixed by re-running the same `systemctl disable`
directly against `/mnt/usb` via `chroot`. Any future BLFS step that *removes* something
(a disabled service, a deleted file) needs this same manual double-check after a tree
redeploy, or `--exclude`/an explicit rmdir step baked into the deploy procedure -- tar
alone won't catch it.

Verified on `/mnt/usb` after the fix: `iwlwifi-8000C-36.ucode` and
`i915/skl_dmc_ver1_27.bin` present under `/usr/lib/firmware`, `/usr/bin/lsusb` present,
`systemd-networkd.service`/`.socket`/`systemd-network-generator.service` all
`disabled`, `NetworkManager.service` `enabled`. Not yet re-tested: an actual boot of
the stick to confirm `iwlwifi` associates and `enp0s31f6` shows connected in `nmcli`.

## 2026-09-03: USB boot test -- GRUB reported the kernel truncated, root cause was ext4 metadata_csum

Booting the stick from the 2026-09-02 redeploy above stopped at GRUB with `error: file
'/boot/vmlinuz-6.18.10-lfs-13.0-systemd' is truncated.` -- the menu and `grub.cfg` itself
loaded fine, only the (12MB) kernel load failed. Mounted `/dev/sda2` back on `/mnt/usb` to
investigate rather than guessing: `e2fsck -f -n` came back clean and the kernel's sha256
matched the chroot tree's own copy byte for byte, so the file wasn't actually corrupt on
disk at that point -- GRUB was misreading it at boot.

Root cause, found by pulling `grub-core/fs/ext2.c` out of `lfs/sources/grub-2.14.tar.xz`
directly rather than assuming: this host's `/etc/mke2fs.conf` `[fs_types] ext4` profile
enables `metadata_csum`, `metadata_csum_seed`, and `orphan_file` by default (confirmed --
`e2fsck` had flagged `orphan_present` as active on the previous format), but `ext2.c`'s
`EXT2_DRIVER_SUPPORTED_INCOMPAT`/`EXT2_DRIVER_IGNORED_INCOMPAT` bitmasks never reference
any of the three. GRUB neither rejects nor accounts for them, so it misreads the extent
tree of any file too large to stay inline in the inode -- small files like `grub.cfg`
never touch that code path, only the kernel did. The `mkfs.ext4 -F -L LFSROOT /dev/sda2`
command in the 2026-09-02 entry above took the host's defaults and never excluded them.

Fixed: operator reformatted `/dev/sda2` with
`mkfs.ext4 -F -L LFSROOT -O ^metadata_csum,^metadata_csum_seed,^orphan_file /dev/sda2`
(this exact flag combination isn't covered by the existing `/etc/sudoers.d/lfs-laptop-deploy`
NOPASSWD pin, which is scoped to the plain no-`-O` invocation -- ran directly by the
operator rather than adding a new sudoers rule). Then, same sequence as before: re-extract
`laptop-lfs-13.0-systemd.tar.zst` (unchanged, still the 2026-09-02 build with the firmware/
NetworkManager fixes -- verified all three survived the fresh extract: `NetworkManager`
enabled, both `systemd-networkd` units and the generator disabled, both firmware blobs and
`/usr/bin/lsusb` present), re-bind-mount and chroot, `grub-install --target=i386-pc
--recheck /dev/sda` (clean, "Installation finished. No error reported."), hand-rewrite
`/boot/grub/grub.cfg` with the new fs-UUID (`751ce7a1-...`, changed by the reformat; the
`root=PARTUUID=219159d2-02` line is untouched since the partition table itself wasn't
touched). Verified: `grub-script-check` clean, post-`umount -R` `e2fsck -f -n` clean with
no `orphan_present` flag this time, kernel sha256 still matches the chroot tree.

Extraction took much longer than the 2026-09-02 redeploy's ~40 minutes -- roughly 45
minutes for the tar itself plus another ~10 minutes of `grub-install` blocked in
uninterruptible sleep behind the kernel's own write-back queue (`/proc/meminfo`'s `Dirty`
was still ~588MB right after the extract returned, and any process touching the device,
including `grub-install`, serializes behind that same write-back). Nothing to fix here --
this is expected on slow USB flash with a large extraction; anyone repeating this deploy
should expect the *whole* redeploy sequence, not just the `tar` step, to run long, and
should check `/proc/meminfo`'s `Dirty` line before assuming a hang.

Updated `BOOTSTRAP.md` step 5's `mkfs.ext4` command for the eventual internal-disk deploy
(`nvme0n1p1`) to carry the same `-O` exclusions -- that target boots through the identical
`grub-2.14` build and would hit the identical failure on first boot otherwise. Also pushed
the current tarball (sha256 `6fd8240a...`, 1,672,728,688 bytes -- a newer build than the
`00:50` copy `server` already had, from the 2026-09-02 firmware/NetworkManager fix) to
`server:~/laptop_backup/laptop-lfs-13.0-systemd.tar.zst`, replacing the stale one.

Not yet re-tested: an actual boot of the stick with this reformatted filesystem. The
`iwlwifi`/`enp0s31f6` network test from the 2026-09-02 entry above is also still
outstanding -- neither has been confirmed on real hardware since the truncation was found.

## 2026-09-03: staged operator config onto the stick for a working `claude` session on boot

Confirmed `grub-install`'s own report ("Installation finished. No error reported."),
`grub-script-check`, and `e2fsck -f -n` all clean after the reformat above -- the raw MBR/
embedding gap itself couldn't be read directly to double-check (`/dev/sda` isn't covered
by the narrow sudoers grant, only specific mount/mkfs/tar/e2fsck/chroot invocations are),
so this is as much verification as is possible short of an actual reboot.

Copied `~/.claude` (448M: settings, credentials, projects, memory) and `~/.ssh` (keys,
`config`, `known_hosts` -- diffed identical to the operator's real `~/.ssh` file list
afterward) onto `/mnt/usb/home/john/`, both writable directly as `john` since that's the
UID the extracted tree already runs as. `claude` itself was already installed at the
user-level npm prefix (`~/.npm-global`, from the 2026-09-01 entry), just not on `PATH` in
a bare non-login shell -- confirmed working via `chroot ... su - john -c 'claude
--version'` (2.1.258).

The `~/agent-built-lfs` repo clone from the 2026-09-02 entry was gone -- it had been
written directly onto that session's `/mnt/usb` mount rather than into the chroot tree
itself, so this reformat's fresh tarball extract didn't carry it. Re-cloned the same way
(local-path clone, not the raw working tree, to skip gitignored bulk) -- 20M, same as
before. Note: a local clone only carries committed history, so this copy does not include
this session's still-uncommitted doc changes (this entry included).

**Found, not fixed:** `server` resolves through a WireGuard tunnel (`10.0.0.4`, per
`/etc/hosts`; `wg0` is up on the real host right now, confirmed via `ip link`), but the
built tree only has `wireguard-tools` (seq 168) installed -- `/etc/wireguard/` is empty
(no `wg0.conf`), `wg-quick@wg0.service` is disabled, and no overlay file supplies one
either. SSH keys alone don't get the stick to `server` on boot unless it's on the same
LAN as `server-local` (`192.168.0.233`) instead. Deferred rather than fixed outright,
since it needs the operator's own WireGuard private key copied onto removable media --
a bigger step than copying `.ssh`, not something to do without asking first.

## 2026-09-03: Deploy to `nvme0n1p1`/`p2`, and the OneLink+ dock Ethernet fix

**Deploy to the internal disk**, from the USB-booted rescue environment, per
`BOOTSTRAP.md` section 5: `umount /mnt/root` (the old Gentoo root), `mkfs.ext4 -F -L
LFSROOT -O ^metadata_csum,^metadata_csum_seed,^orphan_file /dev/nvme0n1p1` (the
feature exclusions this file already documents -- GRUB 2.14 can't read them),
`mkswap -L LFSSWAP /dev/nvme0n1p2`, extracted `laptop-lfs-13.0-systemd.tar.zst`
(5.3G, exit 0). Bind-mounted `/dev`, `/dev/pts`, `/proc`, `/sys`, `/run`, chrooted in,
`grub-install --target=i386-pc --recheck /dev/nvme0n1` (clean), hand-wrote
`/boot/grub/grub.cfg` (`search --set=root --fs-uuid`, `root=PARTUUID=f1183155-01
rootwait`, no initrd -- same shape as the USB stick's own, still not checked into
`overlay/` anywhere). `grub-script-check` passed. `e2fsck -f -n` clean both before and
after all subsequent work (130406 then 130419 files, 0 errors).

Root turned out **locked** (`passwd -S root` => `L`) despite this file's own step 4
calling for a password before archiving -- never actually done. Left it locked rather
than set one unasked; `john` has a working password and `%wheel ALL=(ALL) ALL` is live
in `/etc/sudoers.d/00-sudo`, so `john` + `sudo` is the path in, same as everywhere else
in this build.

**Reapplied the four post-archive fixes** (`linux-firmware-iwlwifi-8260`,
`linux-firmware-i915-dmc`, `laptop-network-manager-only`, `usbutils`, plus
`ch07-kernfs`) directly into the deployed tree via chroot. These were applied live to
the *USB stick's own* running system on 2026-09-02 (see the entry above) and recorded
in `state/completed`, but that file is shared across the chroot/USB/internal-disk
runs -- the archived tar predates them, so the freshly extracted `nvme0n1p1` tree
didn't have them and `bin/lfsbuild --resume` would have silently skipped them
(`state/completed` already claims them done). Fetched both firmware blobs fresh
(iwlwifi-8000C-36.ucode, skl_dmc_ver1_27.bin -- byte counts matched the earlier USB
run), re-ran the `systemctl disable systemd-networkd.*` fix, rebuilt `usbutils` from
the cached, MD5-verified tarball in `lfs/sources`. Reran `bin/lfsmaint db --host
laptop --root /mnt/target` afterward (311 packages, 101600 files, clean).

**OneLink+ dock Ethernet didn't work post-deploy -- diagnosed and fixed.** The dock's
Ethernet is `lsusb` `17ef:3054 "Lenovo OneLink+ Giga"`, a *separate* USB device from
the onboard Intel I219-LM (`enp0s31f6`) that `kernel-config.sh`'s `E1000E` line
already covers. Its USB interface 0 is class/subclass `02/06` -- standard CDC-ECM, not
a vendor chip, so no `r8152` needed. Nothing bound to it because
`CONFIG_USB_USBNET` (the framework every USB Ethernet class driver depends on) was
never turned on anywhere in this build. Added `USB_USBNET` and `USB_NET_CDCETHER` as
modules to `kernel-config.sh`. The original chroot build directory was already
cleaned up post-archive, so this was a full `make mrproper && make -j2` rebuild (not
incremental), done inside a chroot of the freshly deployed `/mnt/target` tree (42G
free there vs. 9.9G on `/mnt/crypt`) rather than the tight `lfs/` build tree. Config
gate passed clean; `make -j2` respected `host.toml`'s job cap.

Verified live, not just built: both new kernel version strings report identically as
`6.18.10`, so `usbnet.ko`/`cdc_ether.ko` were copied straight into the *currently
running* USB-booted system's own `/lib/modules/6.18.10` and `modprobe cdc_ether`
loaded clean (no vermagic mismatch). `cdc_ether` bound the dock immediately
(`eth0`, `00:50:b6:cd:0a:5b`), NetworkManager brought it up, and it pulled a real DHCP
lease (`192.168.0.210/24`, gateway `192.168.0.1`, working DNS) -- full connectivity
confirmed before ever rebooting onto the internal disk. Removed the 2.7G kernel build
scratch (`/sources/linux-6.18.10`, tarball, logs) from `/mnt/target` afterward; it was
never part of the archived tree's own layout.

Not yet done: the physical reboot onto `nvme0n1p1` itself (operator's own step, per
`BOOTSTRAP.md`), and a permanent `hosts/laptop/overlay/boot/grub.cfg` -- the hand-
written one above still lives only on the deployed disk, same gap `BOOTSTRAP.md` has
flagged since 2026-08-28.

## 2026-09-03: `start-hyprland.sh` launcher, and two real defects it exposed

Requested: a `~/start-hyprland.sh` for `laptop`, the Hyprland equivalent of server's
`overlay/home/john/start-awesome.sh`. Written to
`hosts/laptop/overlay/home/john/start-hyprland.sh` and deployed to the live host.
Initially documented here as not needing `__GLX_VENDOR_LIBRARY_NAME` (assumed
`glvnd=disabled` from the tier plan) -- **wrong, corrected same day**: this host's
`blfs-mesa` override actually reversed to `glvnd=enabled` on 2026-08-31 (aquamarine's
CMakeLists hard-requires the GLVND-specific `OpenGL::OpenGL` CMake target), so libglvnd
is real and active here (`libGLX.so`, `/usr/share/glvnd/egl_vendor.d/50_mesa.json`
confirmed present live). The script now sets `__GLX_VENDOR_LIBRARY_NAME=mesa`, same as
server's own launcher and for the same reason (XWayland doesn't implement
`GLX_EXT_libglvnd`). `seatd` (standalone server, enabled) and `john`'s
`seat`/`video`/`input` group membership were already correct from the original build.

**Real defect found testing it, unrelated to the script itself: `/` on the live host
was owned by `john:john`, not `root:root`.** `systemctl status
systemd-tmpfiles-setup.service` showed it exiting status 73, logging "Detected unsafe
path transition / (owned by john) -> /var (owned by root)" for every rule it tried to
apply -- meaning no tmpfiles rule had actually run since boot, `/run/user` included
(and, more broadly, whatever persistent-journal/`/tmp` setup those rules were supposed
to do). Root cause not fully traced (deploy-time extraction likely never wrote an
explicit ownership entry for the tree's own top-level directory), but the fix is safe
and narrow: `chown root:root /` (the directory entry only, no `-R` -- nothing under it
was touched). Confirmed fixed: `stat` now shows `root:root`, and `systemd-tmpfiles
--create` (the setup service itself refuses manual re-invocation, `RefuseManualStart`)
ran clean afterward, creating `/run/user` (`0755 root root`, systemd's own
`/usr/lib/tmpfiles.d/systemd.conf` rule).

That still leaves the per-uid subdirectory missing -- `/run/user/1000` is normally
created by `pam_systemd` at login, and this box has no PAM either, the identical gap
server hit building its own `start-hyprland.sh` (see the 2026-08-xx entry above: fixed
there with a static tmpfiles rule rather than the temporary-sudo route). Same fix
applied here: `/etc/tmpfiles.d/xdg-runtime-john.conf` (`d /run/user/1000 0700 john
john -`), applied immediately, persists across reboots on its own.

**Second real defect, found running the launcher for real**: Hyprland itself started
cleanly (event loop, config manager -- picks up `~/.config/hypr/hyprland.lua`,
symlinked to the operator's separate `~/Config` dotfiles repo, not part of this
project), but XWayland's embedded X server failed outright on keyboard init: `sh:
/usr/bin/xkbcomp: No such file or directory`, `XKB: Failed to compile keymap`, `Fatal
server error: Failed to activate virtual core keyboard`. `xkbcomp` is the exact
hand-authored, no-BLFS-page package server already hit and fixed building its own
Hyprland stack (`hosts/server/packages.py` seq 197, "hand-authored from xorg's own
gitlab, matching Arch's xorg-xkbcomp 1.5.0") -- it was simply never carried over to
laptop's own `packages.py`. Added as `hand(193, "xkbcomp", ...)` (laptop's own next
free seq, independent numbering from server's), reusing the existing shared
`recipes/blfs-xkbcomp.sh` verbatim -- deps (`libxkbfile`, `xorgproto`) already built in
Tier 9. `bin/extract-blfs.py --host laptop --check` confirmed zero drift before and
after regenerating the plan.

Built for real, natively, on the live host (`bin/lfsbuild --host laptop --blfs --only
blfs-xkbcomp --native`, matching how `server` maintains itself post-deploy): 0.1 min, 3
files (`/usr/bin/xkbcomp`, its `.pc`, its man page). Required root; delivering a sudo
password through a piped `ssh -tt` session proved unreliable (the first attempt hung
indefinitely on the build's very first internal `sudo install -d` call and had to be
killed -- confirmed no orphaned processes left behind). Operator enabled the existing
`%wheel ALL=(ALL) NOPASSWD: ALL` grant in `/etc/sudoers.d/00-sudo` (already
server's own standing policy, not a new hack) rather than have this session add a
temporary one; **left enabled at the operator's explicit request, more work planned
before it gets reverted -- do not revert without asking.**

Re-ran the launcher after the fix: XWayland now compiles the keymap (two non-fatal
`xkbcomp` warnings -- unsupported max keycode 708 clipped, a duplicate virtual
modifier definition -- both explicitly noted as non-fatal by `xkbcomp` itself) and gets
well past the point of the original crash; the 5-second test run was torn down by the
test harness itself (`(EE) failed to read Wayland events: Broken pipe`), not a new
failure. Full interactive verification (a real session on the physical console, an
actual monitor/keyboard/mouse) is still outside what this SSH-driven process can
exercise, the same limitation both hosts have hit at this stage of their builds.

## 2026-09-03 (continued): real interactive session -- tofu boxes, dead keybindings,
## a corrected glvnd claim, and a GTK3 rebuild for wofi

Operator started the launcher for real (not a timed SSH test) and watched the actual
screen -- the laptop is currently docked, external displays live (`DP-3` "Sony SONY
TV", `DP-5` "Acer V193W" via the OneLink+ dock; the internal `eDP-1` panel enumerates
as `connected` in DRM but Hyprland reports it `disabled: true`, consistent with a
docked/lid-closed session rather than a driver gap -- not investigated further, not
reported as a problem). `hyprctl monitors`/`instances` confirmed a real running
compositor instance the whole time, not a synthetic/headless one.

**Correction to the entry above**: it claimed no `__GLX_VENDOR_LIBRARY_NAME` override
was needed because "mesa was built with `glvnd=disabled`" -- wrong. Re-checking
`hosts/laptop/blfs-overrides.json` directly: `blfs-mesa`'s override reversed to
`glvnd=enabled` on 2026-08-31 (aquamarine's CMakeLists hard-requires the GLVND-specific
`OpenGL::OpenGL` CMake target), and libglvnd is confirmed live (`libGLX.so`,
`/usr/share/glvnd/egl_vendor.d/50_mesa.json`). `start-hyprland.sh` now sets
`__GLX_VENDOR_LIBRARY_NAME=mesa`, matching server's own launcher, for the same
XWayland/`GLX_EXT_libglvnd` reason.

**Two real, operator-visible defects, both fixed:**

1. **Every glyph rendered as a tofu box ("squares")** -- `fc-list` returned zero fonts
   system-wide. Exact same gap and fix server already has (`hand(206-207, ...)` there)
   but never carried to laptop. Added `dejavu-fonts-2.37` (SourceForge,
   `dejavu-fonts-ttf-2.37.tar.bz2`, matches Arch's `ttf-dejavu`) and
   `jetbrains-mono-fonts-2.304` -- the operator's mirrored `alacritty.toml` explicitly
   names "JetBrains Mono". **JetBrains' own release asset is a `.zip`; `bin/lfsbuild`'s
   generic unpack step is unconditional `tar -xf`, no zip support** (confirmed: GNU tar
   1.35 refuses it outright, "This does not look like a tar archive"). Server's own
   completed build of this step must predate this gap or worked around it outside the
   driver -- not visible in the current recipe. Worked around by re-packing the same
   official contents into `JetBrainsMono-2.304.tar.gz` (`unzip` then `tar -cz`, same
   top-level dir name) so the step flows through the normal pipeline unmodified; the
   recipe itself (`fonts/ttf/*.ttf`) needed no change. Both built live: 28 + 32 files.
   `fc-list` now reports 54 fonts.

2. **SUPER+Return (alacritty) and SUPER+D (wofi) did nothing** -- neither binary was
   ever built here. `alacritty` (seq 196): shared recipe reused verbatim from server,
   Rust/cargo release build, 3.7 min, 5 files. `wofi` (seq 197): **never actually
   completed anywhere in this project** -- server's own attempt was part of the
   Hyprland/Wayland branch abandoned for X11/awesome; recipe recovered from git history
   (`7efd90e^:recipes/blfs-wofi.sh`) and restored to the shared tree, this is its first
   real build. Source: `hg.sr.ht/~scoopta/wofi` (Arch's own upstream for
   `xorg-xkbcomp`-style sourcing), tag `v1.5.3`.

   First `wofi` attempt failed for a real reason: `fatal error: gdk/gdkwayland.h: No
   such file or directory`. GTK3 here was built from **the book's own literal default**
   (`x/gtk3.html` block 0: `-D wayland_backend=false`) -- correct for server (X11/
   awesome only), wrong for laptop, this project's actual Wayland host. Operator asked
   to additionally sweep for any other package with a similar Wayland-support gap;
   grepped every recipe laptop actually uses for wayland-related build flags. Only
   three other packages have a `wayland` toggle at all (`dunst`, `rofi`, both explicitly
   server's own abandoned-Hyprland-era X11 replacements, not part of laptop's plan) --
   `sdl2-compat`/SDL3 (built here) uses runtime `dlopen` for its Wayland backend, not a
   build-time flag, and already has it (confirmed: `libwayland-client.so.0`/
   `libwayland-egl.so.1` referenced in `libSDL3.so.0`'s strings). GTK3 was the only real
   gap.

   Added a `hosts/laptop/blfs-overrides.json` entry flipping `wayland_backend` to
   `true` (x11/broadway stay on too -- both backends coexist in the same `libgtk-3.so`,
   selected at runtime via `GDK_BACKEND`, so this is additive, not a replacement).
   Generates `hosts/laptop/recipes/blfs-gtk3.sh` per CLAUDE.md's host-override
   mechanism. Rebuilt live (`--force`, source tarball re-fetched from
   `download.gnome.org` since the original was already cleaned up): 763 files.
   Confirmed both `gdk-wayland-3.0` and `gdk-x11-3.0` pkg-config modules present
   afterward -- Firefox's existing GTK3/X11 usage untouched. `wofi` then built clean:
   18 files.

**Verified live, in the operator's already-running session, not just built**:
`hyprctl dispatch` needed the config's own Lua call form
(`hl.dsp.exec_cmd("alacritty")`), not the classic `.conf`-style `exec alacritty` --
this Hyprland build evaluates raw dispatch strings as Lua when a `.lua` config is
active, confirmed by the error text literally showing the wrapped Lua source
(`[string "return hl.dispatch(exec alacritty)"]`). `alacritty` opened as a real client
(`hyprctl clients`: `class: Alacritty`); `wofi` opened as a real layer-shell surface
(`hyprctl layers`: `namespace: wofi`, correct geometry on `DP-3`). `fc-list` confirms
both new font families registered. Noticed in the log around this same window: a
`Session got deactivated!` / `[libseat] Disabling seat` sequence with every input
device reported removed, then reinitialized, plus one `ERR: BUG THIS: key not found in
m_dPressedKeys` -- consistent with a VT switch or physical seat handoff during the
operator's own interaction, not something introduced by tonight's changes; not
investigated further since both apps launched successfully right after.

Not attempted, out of scope for tonight: `chromium` (SUPER+B in the operator's real
config) and `dolphin` (SUPER+E) have no build path in this project (no Chromium/KDE
Frameworks recipes exist anywhere) -- both keybindings will keep doing nothing, a
pre-existing condition of the operator's shared dotfiles, not a new finding.
`XCursor couldn't find shape left_ptr, using default cursor instead` (seen in the
original log, cosmetic -- Hyprland falls back to a default cursor) is a real, never-
resolved gap on **both** hosts (server's own `packages.py` explicitly defers "a cursor
theme is a later, separate concern") -- not fixed here, flagged for whenever that's
wanted. Screenshot/clipboard utilities from server's old Hyprland-era wishlist
(`grim`, `slurp`, `wl-clipboard`, `wlsunset`, `hyprshot`, `cliphist`) are not in
laptop's `packages.py` at all -- a real gap if the operator wants them, not raised
unprompted here.

## 2026-09-03 (continued): VAAPI was never actually wired up -- found via a real hwdec test

Operator asked for a concrete test: download the same clip in x264/x265/vp9 (`yt-dlp`,
newly `pip install --user`ed -- `~/.local/bin` was already on `PATH` via
`bashrc.local`, no fix needed) and confirm hardware decode in `mpv`. YouTube doesn't
serve HEVC for the requested video at all (only AV1/VP9/H.264) -- transcoded the x264
download to HEVC locally with `ffmpeg`'s already-built `libx265` encoder to get a real
x265 test file, rather than skip that codec silently.

**Both `ffmpeg` and `mpv` turned out to already be built** (contradicting this file's
own 2026-08-31 "deliberately not built" note -- stale since Firefox needed the GTK3
half of that deferral, and it seems mpv/ffmpeg got swept in as part of the later media
codec tier without a narrative entry). `mpv --hwdec=vaapi --vo=gpu` on the x264 file
failed outright: `libva: Trying to open /usr/lib/dri/iHD_drv_video.so ...
va_openDriver() returns -1`, same for `i965_drv_video.so`. Root cause: **VAAPI was
never actually wired up on this host.** `libva` (seq 146, the dispatch library) was
built, but this project's own comment on that line -- "VAAPI hardware video accel
through mesa's iris driver" -- is a real misconception: mesa's `iris` is the
OpenGL/Vulkan driver; Intel VAAPI decode needs a separate backend package that mesa
does not provide. Confirmed by the fact that `/usr/lib/dri/{iHD,i965}_drv_video.so`
simply didn't exist. Added `gmmlib` (seq 211, intel-media-driver's own Required dep)
and `intel-media-driver` (seq 212, the modern `iHD` backend Intel recommends for
Gen8+ -- this is Gen9/Skylake -- over the older `i965_drv_video.so`). Book's own
kernel-config note for this page (`DRM_I915`) was already satisfied. Both built live,
zero drift. `intel-media-driver`'s block 0 (an example `grep` command for identifying
a GPU's generation from its PCI ID) auto-disabled correctly, not a real build step.

**Full VAAPI result, all three codecs, `mpv --hwdec=vaapi --vo=gpu` with
`WAYLAND_DISPLAY` correctly set** (an earlier test run without it fell through to a
raw DRM backend and collided with Hyprland's own DRM master -- `Failed to acquire DRM
master: Permission denied` -- a test-harness mistake, not a real defect, since the
Wayland path works fine once the env var is actually set):
- H.264: `Using hardware decoding (vaapi)` -- confirmed.
- HEVC: `Using hardware decoding (vaapi)` -- confirmed.
- VP9: `Hardware decoding of this stream is unsupported?` -- **not a bug**. Intel
  didn't add a VP9 fixed-function decode block until Kaby Lake (Gen9.5); this is
  Gen9 Skylake. `iHD_drv_video.so` loads and probes formats fine, it just has
  nothing to offer for VP9 on this silicon -- software decode is permanent here,
  not a gap this project can close.

**Operator then asked to confirm all three consumers (mpv/ffmpeg/Firefox) are
actually configured to use it, not just capable of it:**
- `mpv`: already correctly configured in the operator's own `~/Config` dotfiles
  (`hwdec=vaapi`, `vo=gpu` in `mpv.conf`) -- nothing to change. That file's
  `ytdl-format` already excludes vp9/av1 for embedded playback, which lines up
  exactly with the hardware limitation just confirmed above -- the operator (or
  whoever wrote that config) had already worked around this before it was
  formally diagnosed here.
- `ffmpeg`: no persistent config exists for hwaccel (it's a per-invocation flag,
  `-hwaccel vaapi`); already proven working via the x265 transcode and the mpv
  tests above, which both exercise the same `libva`/`iHD_drv_video.so` path.
- `firefox`: **not configured by default**. `prefs.js` had zero VAAPI-related
  settings before this -- meaning any video played earlier tonight (before
  `intel-media-driver` even existed) silently used software decode, no visible
  symptom either way. Added
  `~/.mozilla/firefox/ftfaevf4.default-default/user.js` (the profile matching
  `profiles.ini`'s actual `Install<id>` default, not the older, unused
  `y77rja4t.default` profile also listed there) setting
  `media.ffmpeg.vaapi.enabled`, `media.hardware-video-decoding.force-enabled`,
  and `widget.dmabuf.force-enabled` to `true`. `media.rdd-ffmpeg.enabled` was
  also written but didn't survive into `prefs.js` -- not a recognized pref name
  in this Firefox version (140.8.0esr), dropped silently rather than erroring;
  the three that did apply are the ones that actually matter. Restarted Firefox,
  opened a local test file, and confirmed live in `/proc/<rdd-pid>/maps`:
  `iHD_drv_video.so` was not loaded on first launch (nothing had played yet) and
  *was* loaded once real playback started -- the RDD process genuinely engages
  the hardware path now, not just linked-but-unused.

Not part of `agent-built-lfs`: the mpv/Firefox config lives in the operator's
separate `~/Config` dotfiles repo, edited directly on the live host. That repo's
laptop checkout (like this one) has no working GitHub SSH key from this
non-interactive session -- commits there are local-only until the operator pushes
from an interactive shell where their `pass`-based agent bootstrap runs.

## 2026-09-03 (continued): GTK4/gtkmm/pavucontrol chain, and a Qt6 disk-space incident

Operator: "move forward with the remaining builds" -- the GTK4/pavucontrol chain
queued earlier, plus Qt6 (for a future DankMaterialShell/Quickshell build).

**Qt6 attempted first, aborted by design.** Fetched `qt-everywhere-src-6.10.2.tar.xz`
(1.3G) and ran `bin/lfsbuild --only blfs-qt6 --native`. A disk-space safety monitor
(a plain shell loop polling `df` every 60s, killing the build under a threshold) was
running alongside it as instructed. Disk usage climbed past what BLFS's own 50GB
estimate implied was safe on this host's ~41GB free, and the monitor correctly fired
at 692MB free -- but it killed the *outer* wrapper script directly rather than
letting it exit its own cleanup step, so two child processes (the recipe script, a
`ninja`) survived the kill and kept writing until the filesystem hit **99% full,
690MB free**, a real risk on a live daily-driver machine. Killed the stragglers by
PID, removed the leftover `/sources/qt-everywhere-src-6.10.2` tree by hand (reclaimed
back to 38GB free), confirmed no failed services and no disk-full journal entries.
`blfs-qt6` correctly never entered `state/completed`. Qt6 itself is still queued,
not reattempted this session.

**GTK4/pavucontrol chain: 6 real build failures across ~4 hours, each fixed on its
own merits rather than guessed at speculatively:**

1. `blfs-cairomm`: book's own default (`-D build-tests=true`) fails outright --
   meson's own error names the fix: `-D build-tests=false` (Boost Test, Recommended
   and only needed for tests, isn't installed). Host override added.
2. `blfs-gtk4` block 0: book's own default (`-D vulkan=enabled`) fails --
   `Program 'glslc' not found`. `glslc` is Google shaderc's GLSL->SPIR-V compiler, a
   real new dependency chain on top of what mesa already needed (SPIRV-Tools/
   glslang) for no benefit pavucontrol needs -- Vulkan is an optional alternate GTK4
   render backend alongside GL, not a functional requirement. `-D vulkan=disabled`.
3. Still block 0: `-D documentation=false` (added expecting it to gate doc-tool
   probing) did **not** prevent meson from unconditionally falling back to building
   the `gi-docgen` subproject, which itself needed Python `markdown`/`pygments`/
   `typogrify` (none installed) -- `documentation=false` only controls whether the
   final HTML actually gets installed, not whether meson checks for the tools that
   *could* build it. Fixed directly rather than chasing more meson flags: `sudo
   python3 -m pip install markdown pygments typogrify` (this build's `pip` is
   real and already proven working, from the earlier `yt-dlp --user` install).
4. Same spot, one tool further: `rst2html5`/`rst2man` (docutils) also missing --
   same fix, `pip install docutils`.
5. **The actual bug, once the tool-probing genuinely passed**: `blfs-gtk4` blocks 1
   (an *optional* "if you have Gi-DocGen and wish to build API docs" doc rebuild --
   book's own conditional phrasing) and 2 (the *optional* test suite) were still
   enabled by default, since the host override only touched block 0's meson flags.
   Block 1 silently re-enabled `documentation=true` and reran `ninja`, undoing fix
   #3's whole point; block 2 then failed for real (`Test setup 'x11' not found from
   project 'orc'`, an unrelated subproject test-harness gap). Both dropped via
   override -- neither was ever going to be used. **With this actually fixed, GTK4
   built clean: 29.8 minutes, 2248 files.**
6. `blfs-gtkmm4` block 2: same conditional-doc pattern as fix #3/4, book's own text
   says "If you have built the documentation... it was installed to
   /usr/share/doc/gtkmm-4.0" -- no Doxygen here, so the `mv` of that nonexistent
   directory failed outright. Dropped.

**Real process-management bug found and fixed mid-session, unrelated to the builds
themselves**: every disk-space safety monitor spawned for these resumed builds used
`pgrep -f 'lfsbuild --host laptop --blfs --from blfs-XXX'` as its loop-exit
condition. `pgrep -f` matches a process's *full command line* -- and the monitor's
own `bash -c "while pgrep -f '<that exact string>' ..."` invocation contains the
search string as a literal substring of itself, so every single monitor matched
itself forever and never exited on its own, piling up one per resumed build attempt
(6 stale monitor shells plus one leftover from the earlier x265-transcode wait,
found when the operator asked "why do you have 7 shells running"). Killed all seven,
switched to PID-based liveness checks (`kill -0 $PID`) for every monitor from then
on -- immune to self-matching since no search string is embedded in the command
line being checked. One further mistake caught immediately after switching: `pgrep
-f '...blfs-gtk4' | tail -1` briefly returned the wrong PID during one resume
(picked up a stale/unrelated match rather than the actual running `lfsbuild`
process) -- fixed by explicitly verifying the PID against `ps aux` before handing it
to the next monitor, every time, for the rest of the session.

**Final result, all real BLFS/GNOME pages, zero drift** (`bin/extract-blfs.py
--host laptop --check` clean before and after each override): `iso-codes`,
`graphene`, `libsigc++3`, `glibmm2`, `cairomm`, `pangomm2`, `libxinerama` (a real,
undocumented `gtk4` meson.build hard dependency, same class of gap as `xkbcomp`
earlier -- found live, not from the book's own dependency list), `gtk4`, `gtkmm4`,
`json-glib`, `pulseaudio` (client library only, matching the earlier plan --
service never enabled), `pavucontrol`. Verified live in the operator's actual
Hyprland session, not just built: `pavucontrol` opens as a real window (`hyprctl
clients`: `class: org.pulseaudio.pavucontrol`, `title: Volume Control`). 33.2GB free
on `/` when the chain finished -- comfortably clear of the disk pressure Qt6 hit.
## 2026-09-03 (continued): pass (password manager) and Bluetooth (bluez userspace)

Operator-requested: `pass` and Bluetooth. Twelve real BLFS/hand-authored steps, seq
213-224, all built native, zero disk drama (34GB free throughout, barely moved).

**pass chain (seq 213-222), same dependency tree `server` already solved (its own seq
75-83, 171) -- versions checked directly against this book snapshot, not assumed from
server's history, and all matched exactly:** libgpg-error-1.59, libgcrypt-1.12.0,
libassuan-3.0.2, libksba-1.6.7, npth-1.8, openldap-2.6.12, pinentry-1.3.2, gnupg-2.5.17,
unix-tree-2.3.1, then the hand-authored `pass` recipe (`recipes/blfs-pass.sh`, shared
with `server`, `password-store-1.7.4.tar.xz` from `git.zx2c4.com`).

One real failure: `blfs-openldap` block 1's `patch -Np1 -i
../openldap-2.6.12-consolidated-1.patch` failed outright, `No such file or directory` --
the book's own "Additional Downloads: Required patch"
(`openldap-2.6.12-consolidated-1.patch`, linuxfromscratch.org) had never been fetched to
`/sources`, unlike every tarball which was. Fetched directly, no md5 published for it in
the book, rebuilt clean: 291 files.

Also hit, unrelated to any single package: `/sources` is owned `root:root 755` --
plain `wget` as `john` fails `Permission denied` on write. All twelve tarball fetches (and
the openldap patch) went through `sudo wget` instead once this was found; every step's
own build already runs via `sudo`/root internally so this only affected the fetch, not
the build.

Verified live afterward: `gpg --version` reports 2.5.17/libgcrypt 1.12.0 real and
working; `pass` runs and lists the operator's existing `~/.password-store` tree (predates
this build, synced in separately -- not something this chain created). `pass`'s own
runtime deps (bash, gnupg, tree) all present and correct.

**Bluetooth (seq 223-224):** `libical-3.0.20` (real BLFS page, bluez's own Required
dependency, nothing else in this project needs it) then `bluez-5.86`. Kernel-side
Bluetooth support (`CONFIG_BT` and everything under it, confirmed unset in the running
kernel earlier this session) is queued in `hosts/laptop/kernel-config.sh` but not yet
rebuilt/rebooted into -- out of scope for this pass, handled separately.

One real failure: `blfs-libical` block 0's cmake configure failed --
`CMake Error: valac, the Vala compiler was not found. Install it or disable Vala
bindings with -DICAL_GLIB_VAPI=False.` Book's own default (`ICAL_GLIB_VAPI=true`) needs
Vala-0.56.18, a Recommended dependency "both required for GNOME" per the book's own
dependency line -- nothing in this project actually consumes libical directly (it exists
purely as bluez's own dependency, for the plain C library), so there is no GNOME/Vala
consumer to justify a whole new toolchain for one optional feature. Same class of call as
`blfs-gtk4`'s `vulkan=disabled`: fixed with the exact flag the tool's own error message
named (`-D ICAL_GLIB_VAPI=false`), not by building the missing dependency. Host override
added; rebuilt clean, 116 files. Two doc blocks (1 and 3) were already dropped ahead of
the actual build via override -- same class of conditional-prose-not-structure classifier
gap gtk4/gtkmm4 already hit (`make docs`/API-doc install, gated on Doxygen/Graphviz/
GTK-Doc, none of which are built here).

`bluez` itself built clean on the first try, 130 files. Verified live:
`bluetoothctl --version` reports 5.86, `/usr/libexec/bluetooth/bluetoothd` exists and
`/usr/sbin/bluetoothd` symlinks to it correctly (book's own convenience symlink),
`bluetooth.service` is loaded and enabled (systemd unit installed and enabled per the
book's own instructions) but correctly `inactive (dead)` right now -- expected, not a
failure: this project's kernel does not yet have `CONFIG_BT_HCIBTUSB` built, and per the
book's own note, "Systemd will start the Bluetooth daemon only when a bluetooth device is
detected on the system." Real end-to-end Bluetooth (adapter visible, `bluetoothctl list`
non-empty) needs the queued kernel rebuild and a reboot, both separate work.

All 12 steps: manifests non-empty (5-352 files each), all recorded in
`hosts/laptop/state/completed`. Free space unchanged in any meaningful way (33.1-33.2GB
throughout) -- none of these packages are large. `bin/extract-blfs.py --host laptop
--check` clean before and after every override.

## 2026-09-03 (continued): Bluetooth kernel rebuild -- staged, reboot deferred by operator

Kernel side of the Bluetooth work above. `hosts/laptop/kernel-config.sh` got a new
section (book's own Kernel Configuration block from `bluez.html`, minus the
Cryptographic API sub-block -- only needed for bluez's own test suite, not run here --
and minus BT_HCIBTSDIO/BT_HCIUART, since the real hardware confirmed live is USB:
`BT`, `BT_BREDR`, `BT_RFCOMM`(+TTY), `BT_BNEP`(+MC_FILTER+PROTO_FILTER), `BT_HIDP`,
`BT_HCIBTUSB`, all modules except the two BREDR/BNEP-filter bools the book lists as
built-in features of the Bluetooth-classic/BNEP modules themselves.

Same version rebuild (6.18.10, not a version bump), which means `make install` writes
back to the exact same live filenames already in `/boot` and `/lib/modules/6.18.10` --
unlike a version bump, there is no natural side-by-side fallback. Given this is the
operator's daily driver with no documented physical/serial console recovery path in this
session, backed up before running the rebuild rather than trusting the boot-path gate
alone (which only asserts the *existing* boot-critical set, SCSI/ATA/NVMe/USB/ext4/tmpfs
-- true here since nothing in this change touches any of them, but backing up costs
nothing and removes the only real unbounded-risk scenario, a kernel that fails to boot at
all with no way back short of physical USB rescue media):

- `/boot/vmlinuz-6.18.10-lfs-13.0-systemd`, `/boot/System.map-6.18.10`,
  `/boot/config-6.18.10` each copied to a `.preBT` sibling before the rebuild.
- `/boot/grub/grub.cfg` backed up to `.preBT-backup` and a second menuentry appended
  ("...pre-Bluetooth fallback (2026-09-03)") pointing at the `.preBT` vmlinuz, same
  `root=PARTUUID=` line as the primary entry. `default=0`/`timeout=5` untouched --
  the new kernel stays the boot default, the fallback is there to select manually if
  needed, not automatic.
- Staged `hosts/laptop/kernel-config.sh` and `bin/kernel-config-base.sh` to
  `/sources` by hand first -- `bin/lfsbuild` does not do this itself, and this host's
  `/sources/kernel-config*.sh` did not exist yet (first kernel rebuild run from this
  particular checkout's copy of the file). Fetched `linux-6.18.10.tar.xz` fresh too,
  same reason -- not cached from the original build.

Built with `bin/lfsbuild --host laptop --native --only ch10-kernel --force`
(MAKEFLAGS=-j2, respecting `host.toml`'s cap). Gate passed clean:
`### kernel config gate passed: boot path built in, no initramfs needed` /
`ok   default cpufreq governor is schedutil` -- both asserted, neither this
session's own change, confirming nothing already-working regressed. New
`btusb.ko`/`bluetooth.ko`/`rfcomm.ko`/`bnep.ko`/`hidp.ko` all present under
`/lib/modules/6.18.10/kernel/{drivers/bluetooth,net/bluetooth}`, confirmed by listing
the tree directly rather than trusting the build log alone.

`bin/lfsbuild`'s own auto-`detect_mode()` picks `chroot` by default on this host --
worth restating since it bit this exact session -- because a stale, superseded
pre-deploy chroot tree still sits at `/mnt/crypt/john/projects/agent-built-lfs/lfs`
with a populated `usr/bin`, and `detect_mode()` checks for that tree before checking
whether this machine is itself LFS. `--native` is not optional here; every invocation
in this session used it explicitly.

**Not rebooted.** Asked the operator directly rather than assuming the broader
Bluetooth/pass authorization covered an actual reboot of their live daily driver --
correctly, since they said no, they'll reboot it themselves later. New kernel, modules,
and fallback are all staged and verified; nothing further happens here until that
reboot, at which point `bluetoothctl list`/`rfkill list` should show a real adapter for
the first time (currently `bluetooth.service` is loaded+enabled but inactive, per the
book's own note that systemd only starts `bluetoothd` once the kernel exposes a real
device -- expected on the still-running pre-Bluetooth kernel, not a failure).

## 2026-09-04: Quickshell/DankMaterialShell -- qt6 build attempted, stopped on a real concurrency collision, not a code bug

Operator-requested (2026-09-04, continuing from 2026-09-03's PAM decision): build the
trimmed qt6 (seq 199, `-submodules qtdeclarative,qtsvg,qtshadertools,qtwayland,
qtmultimedia` override already recorded 2026-09-03), then cli11/quickshell/matugen/
dankmaterialshell (seq 225-228, all queued, all hand-authored recipes already staged).
None of the four new steps were reached -- qt6 itself never completed.

**Background-process survival bug found and fixed first.** The first qt6 attempt
(07:14, backgrounded with plain `nohup ... & disown`) died silently around 65 minutes
in, 4217/8050 ninja targets built, `ninja: build stopped: interrupted by user` --
not a crash, not OOM (`free -h` showed 5+GB free, no `dmesg` OOM-killer entries).
Root cause: `systemd-logind`'s `KillUserProcesses` (commented out in
`/etc/systemd/logind.conf`, meaning it runs on systemd's own compiled-in default,
which is `yes`) kills every process belonging to a user's login session when that
user's *last* session ends -- `nohup`/`disown` protect against SIGHUP from a closing
terminal, not against logind's own session-scope cleanup, a different mechanism
entirely. `loginctl list-sessions` showed zero sessions at the time this session's own
SSH connection was the only thing keeping the user "logged in"; closing it (an
artifact of how one-shot `expect`-wrapped SSH commands work here, not an intentional
disconnect) triggered the kill. Fixed by switching every long-running remote command
to `sudo systemd-run --unit=<name> --collect --uid=john --gid=john
--working-directory=... --setenv=HOME=/home/john -- <command>` -- a real transient
systemd unit under `system.slice`, independent of any login session, immune to this
class of kill. Confirmed working: the second qt6 attempt survived multiple SSH
reconnects cleanly (`systemctl status` showed it still running, correct cgroup,
correct working directory, throughout). Worth carrying forward as standing practice
for this host: any build expected to outlive a single SSH command needs
`systemd-run`, not `nohup`.

**Second and third qt6 attempts both failed with different-looking but related
errors** (`rm: cannot remove 'qt-everywhere-src-6.10.2': Directory not empty` once,
`./configure: No such file or directory` twice) despite the driver's own generated
script (`/sources/.build/blfs-qt6.sh`, read directly off disk, not re-derived) being
verified byte-correct: `cd /sources; rm -rf srcdir; tar -xf tarball; cd srcdir` in
that exact order, recipe running as a child process inheriting that cwd, matching
`bin/lfsbuild`'s own documented design exactly. A manual, isolated reproduction of the
same extract+cd+ls sequence succeeded cleanly on its own. The two symptoms together
(sometimes the directory won't empty, sometimes it's empty when something else
expects content) are the signature of two writers touching the same path
concurrently, not a script bug -- and a live `ps -eo pid,ppid,tty,stat,etime,cmd`
check found exactly that: a second, independent Claude Code session (`pts/2`, PID
1022038, started roughly 3 minutes before this session's second qt6 attempt) running
directly on this laptop, under the operator's own real local Hyprland session
(`tty2`, up since the 13:31 reboot on 2026-09-03, i.e. genuinely the operator
physically at the machine) -- with a live `sudo bash -c 'cd /sources && rm -rf
qt-everywhere-src-6.10.2 && tar -xf ...'` process still attributable to that other
session at the moment of inspection. Two agents extracting/removing the same tarball
into the same path at the same time, uncoordinated, is sufficient on its own to
produce every symptom seen -- no further diagnosis attempted past this point.

**Stopped here rather than retry against a resource another live session is also
using.** Nothing was deleted or force-overwritten beyond the tarball's own working
directory (`/sources/qt-everywhere-src-6.10.2`, always disposable, recreated from the
tarball on every attempt regardless). `qt6` is not in `state/completed`; the four new
steps (cli11, quickshell, matugen, dankmaterialshell) were never attempted. Free space
unaffected either way (33-34GB throughout, no disk risk from this). Whatever the other
session on `pts/2` is doing with the same qt6 build is unknown from here -- worth
checking with the operator directly before either session retries, rather than
guessing at coordination.

**Resolved same day**: confirmed with the operator that `pts/2` was their own real,
local Claude Code session on this machine, physically at the console. Ended (operator
killed it); a live check afterward found no `claude` process, no `pts/2`, no
`who`/`w` sessions at all, and no lfsbuild/qt6/ninja processes left running. The
collision explanation holds and the machine is otherwise idle.

## 2026-09-04 (continued): USB webcam (UVC), the wireplumber/pipewire config gap, session paused

Two more real gaps found live, both fixed, before pausing this whole line of work at
the operator's request to let them continue from the laptop's own console instead.

**USB webcam -- Logitech HD Pro Webcam C920.** Operator plugged it in mid-session.
`lsusb`/`dmesg` both show it enumerating cleanly (`046d:082d`), but no `/dev/video*`
ever appeared. Checked every `CONFIG_MEDIA_*`/`CONFIG_VIDEO_*`/`CONFIG_USB_VIDEO_CLASS`
symbol directly against `/boot/config-6.18.10`: all unset -- this kernel's entire
V4L2/media subsystem was absent, not just the one driver. No BLFS book page for this
(pure kernel Kconfig, no userspace package required for the driver itself). Added to
`hosts/laptop/kernel-config.sh`, alongside the already-staged Bluetooth section:
`MEDIA_SUPPORT`, `MEDIA_USB_SUPPORT`, `MEDIA_CAMERA_SUPPORT` (enabled, menu-gating
bools), `VIDEO_DEV` and `USB_VIDEO_CLASS` (modules). `MEDIA_CONTROLLER` and the
`VIDEOBUF2_*` buffer-queue helpers `uvcvideo` needs are left to Kconfig's own
`select`-driven auto-resolution (`make olddefconfig`), same pattern as `BT`'s
sub-options -- not yet verified against a real build the way `BT_HCIBTUSB` was
(`grep`ping the built `/lib/modules` tree for `uvcvideo.ko`), since **the kernel was
never rebuilt with this addition** -- queued alongside Bluetooth for the next kernel
rebuild, deliberately not rebuilt tonight to avoid a second CPU-contending build
while qt6 was (repeatedly) attempting to compile. Pushed to the host; not yet built.

**pipewire/wireplumber were built but never actually wired up.** Operator reported
pavucontrol (built 2026-09-03, GTK4 chain above) showing no audio devices at all --
misdescribed initially as "wireguard" instead of "wireplumber" (corrected in
conversation; WireGuard is the unrelated VPN kernel module, already built for
Tailscale). Real cause, found by reading `wireplumber.html`'s own "Configuring
Wireplumber" section directly: this project's hand-authored `blfs-wireplumber.sh`
recipe (shared, `recipes/blfs-wireplumber.sh`) stopped at `ninja install` and never
included the book's own next section -- disabling real PulseAudio's autostart
(`/etc/xdg/autostart/pulseaudio.desktop`, `/etc/xdg/Xwayland-session.d/00-pulseaudio-
x11`, `autospawn = no` in `/etc/pulse/client.conf`) and enabling the three systemd
--global user units (`pipewire.socket`, `pipewire-pulse.socket`, `wireplumber`).
Confirmed live: the unit files existed on disk (`/usr/lib/systemd/user/{pipewire,
pipewire-pulse}.{service,socket}`, `wireplumber.service`) but `systemctl --global
list-unit-files` showed all three `disabled`, and all three of PulseAudio's real
autostart files were still present and would have raced pipewire-pulse for the same
protocol socket -- exactly the book's documented failure mode ("applications hanging
or malfunctioning"). Fixed two places: the shared recipe itself (so a future rebuild
doesn't regress), and directly on the live host (no rebuild needed for a config-only
fix). Verified: `systemctl --global list-unit-files` now shows `pipewire.socket`/
`pipewire-pulse.socket`/`wireplumber.service` all `enabled`. Takes effect at next
login, not instantly -- no session was active for `john` at the time of the fix
(`loginctl show-user john`: "not logged in or lingering"), confirmed separately from
the `pts/2` collision above (that was a different check, at a different time).

**Session paused here at the operator's request**, to resume from the laptop's own
console rather than this remote/automated one. State handed off:

- **Built and live now, no reboot needed**: `pass` + full gnupg chain, `bluez` +
  `libical`, pipewire/wireplumber's missing systemd-enable step (takes effect next
  login).
- **Staged, needs a kernel rebuild + reboot**: Bluetooth (`CONFIG_BT` and friends) and
  the webcam (`CONFIG_USB_VIDEO_CLASS` and friends), both already in
  `hosts/laptop/kernel-config.sh` on disk, neither rebuilt yet. One rebuild covers
  both -- no need for two separate reboots. `/boot/vmlinuz-6.18.10-lfs-13.0-
  systemd.preBT` and the matching `System.map`/`config` backups plus a grub fallback
  entry ("pre-Bluetooth fallback (2026-09-03)") are already in place from the
  Bluetooth-only rebuild earlier tonight, which was itself never booted into.
- **Written, not yet built**: `cli11`, `quickshell`, `matugen`, `dankmaterialshell`
  hand recipes (seq 225-228, `packages.py`), plus the corrected qt6 `-skip`-based
  trim override (`hosts/laptop/blfs-overrides.json`) -- verified via `bin/extract-
  blfs.py --host laptop --check`, zero drift, but qt6 itself has not completed a
  clean run yet (three attempts tonight, all invalidated by either a wrong flag or
  the `pts/2` collision, none by a real defect in the current override).
- Every file this session touched has been pushed to this host directly (not via
  git -- this host's non-interactive session has no working GitHub key, per the
  earlier note about `pass`'s own bootstrap). The parent session's own separate git
  checkout is being reconciled with this host's real on-disk state and pushed to
  `origin` from there, since it has working credentials this host doesn't.

## 2026-09-04 (first native session, post-reboot): kernel changes verified, and four faults that all traced to two causes

First session running *on* `laptop` itself rather than against it -- the operator
rebooted into the new kernel and asked for four things: verify the staged kernel work,
verify pipewire, and diagnose `upower.service` and `wofi`. All four are answered below.
Two of them turned out to share a single root cause (this system has no PAM), and two
more were silent build defects that had been shipping for days without any failing
unit to point at.

**Environment note, for anything that reads this later.** In native mode on this host
there is no book mirror (`book/13.0`, `book/blfs-13.0` are absent -- they were never
tracked in the repo, and the Gentoo-side LUKS path `chroot_tree` still names,
`/mnt/crypt/john/projects/agent-built-lfs`, no longer exists now that the machine boots
LFS itself). So `bin/extract-recipes.py --check` and `bin/extract-blfs.py --check`
**cannot be run from here**; both exit with "no LFS book at book/13.0". They were not
run this session. Nothing this session changed is a generated recipe, so no drift is
introduced: the edits are `bin/kernel-config-base.sh` (not generated),
`recipes/blfs-pipewire.sh` (hand-authored), and `hosts/laptop/packages.py` (source).
The checks still need to run from a checkout that has the books before the next real
extraction. Also relevant: `/sources` is down to 33 tarballs and holds neither
`pipewire-1.6.0.tar.bz2` nor `wireplumber-0.5.13.tar.bz2`, so the rebuild below needs
them re-fetched first.

### 1. Kernel: Bluetooth landed, the webcam did not, and a third gap turned up

The kernel that booted is the 23:53 Bluetooth rebuild (`/boot/vmlinuz-6.18.10-lfs-13.0-
systemd`, with the 23:18 pre-Bluetooth kernel still in place as
`.preBT` plus its grub fallback entry).

**Bluetooth: the kernel half worked, the firmware half is missing.** Verified against
the running kernel, not the source tree: `/boot/config-6.18.10` has `CONFIG_BT=m`,
`BT_RFCOMM=m`, `BT_BNEP=m`, `BT_HIDP=m`, `BT_LE=y`, `BT_HCIBTUSB=m`;
`bluetooth.ko`/`btusb.ko` are both in `/lib/modules/6.18.10`; `btusb` is loaded with
`bluetooth` bound under it; `hci0` exists in `/sys/class/bluetooth` and in `rfkill
list` (soft- and hard-unblocked, alongside `tpacpi_bluetooth_sw`); and
`bluetooth.service` is now `active` rather than the loaded-but-inactive state it sat in
on the pre-Bluetooth kernel. So the Kconfig work in `hosts/laptop/kernel-config.sh` did
exactly what it was staged to do.

The adapter is still not usable, for a reason one layer up. `dmesg` reads the chip's
bootloader fine, then:

```
Bluetooth: hci0: Failed to load Intel Bluetooth firmware file intel/ibt-11-5.sfi (-2)
Bluetooth: hci0: Reading supported features failed (-56)
```

`-2` is ENOENT: `/lib/firmware` holds only `i915/` and
`iwlwifi-8000C-36.ucode`, the two narrow fetches this project has done
(`blfs-linux-firmware-iwlwifi-8260`, `blfs-linux-firmware-i915-dmc`, both complete).
`intel/ibt-11-5.sfi` was never fetched, so the driver binds the device and then cannot
bring it up -- which is why `bluetoothctl list` and `bluetoothctl show` both return
nothing at all despite `hci0` existing. This is the same narrow-fetch pattern as the
existing two firmware steps and wants a third one; it is *not* a kernel problem and a
kernel rebuild will not help it.

**Webcam (UVC): not in this kernel.** `CONFIG_MEDIA_SUPPORT is not set` in
`/boot/config-6.18.10`, zero `CONFIG_MEDIA_*` lines are set, no `uvcvideo.ko` exists
under `/lib/modules/6.18.10`, and there is no `/dev/video*`. This matches what the
previous session recorded rather than contradicting it -- the media/V4L2 section was
added to `hosts/laptop/kernel-config.sh` *after* the 23:53 build and deliberately not
built that night. It is still staged and still needs a rebuild. The C920 is plugged in
and enumerating (`snd_usb_audio` picks up its mic as card 3), so the moment the modules
exist the device should appear.

**New this session: `CONFIG_USER_NS` is unset, and that is what breaks upower.** See
item 3. Added to `bin/kernel-config-base.sh` (shared, not the host file) -- reasoning in
that file's own comment: the failing unit is upower's own upstream unit, so this is a
fact about running BLFS's packaged units on any machine here, not a laptop hardware
detail. It costs one bool and touches no driver or boot path.

**One rebuild covers both remaining kernel items** (UVC + `USER_NS`), same as the
previous session's note that Bluetooth and UVC could share one. Not run this session --
it is the operator's live daily driver and a rebuild plus reboot is their call.

### 2. pipewire: the systemd wiring was right, but it had no ALSA support and no user manager

Two independent faults, both real, stacked on top of each other. Neither produced a
failing unit, which is why this looked like "pavucontrol shows no devices" rather than
anything diagnosable.

**Fault A -- no user systemd instance at all, because there is no PAM.** The previous
session's fix was correct and is verified still in place: `systemctl --global
list-unit-files` shows `pipewire.socket`, `pipewire-pulse.socket` and
`wireplumber.service` all `enabled`. But nothing was running, and `systemctl --user`
failed outright with "Failed to connect to user scope bus". Cause chain, each step
checked directly:

- `/etc/pam.d` does not exist; there is no `libpam` and no `/usr/lib/security`. And
  `systemctl --version` reports **`-PAM`** -- systemd itself was built without it, by
  the deliberate choice already recorded in `packages.py`'s polkit note.
- `user@.service` relies on `PAMName=systemd-user` for one thing beyond authentication:
  `pam_systemd` is what exports `XDG_RUNTIME_DIR` into the user manager. With `-PAM`
  that directive is inert, so `/usr/lib/systemd/systemd --user` exited 1 with "Trying to
  run as user instance, but $XDG_RUNTIME_DIR is not set".
- With no PAM session, `systemd-logind` never opens a session either:
  `loginctl list-sessions` printed "No sessions" and `loginctl show-user john` said "not
  logged in or lingering" *while the operator's own Hyprland was running on tty2*
  (`who` showed them via utmp; `start-hyprland` pid 468 and `Hyprland` pid 474 were
  live). logind was itself healthy and had seat0. So `user@1000.service` was never even
  asked to start.

Fixed with the two standard PAM-less pieces, both applied live:

- `/etc/systemd/system/user@.service.d/10-no-pam-runtime-dir.conf`, setting
  `Environment=XDG_RUNTIME_DIR=/run/user/%i`. Safe because `user-runtime-dir@%i.service`
  is already `BindsTo=` and ordered before `user@.service`, so the path exists by then.
  The drop-in carries the full rationale.
- `loginctl enable-linger john`, which is what actually starts `user@1000.service` at
  boot when no PAM session will ever open one.

Also added `john` to the `audio` group. Without a logind session there are no device
ACLs on `/dev/snd/*` (they are plain `root:audio 0660`), so group membership is the only
path to the hardware; `john` was in `video`, `input`, `netdev`, `wheel` and `seat` but
not `audio`.

Verified after a `systemctl restart user@1000.service` -- i.e. the boot path, not just a
one-off: `user@1000.service` active, `pipewire.socket` and `pipewire-pulse.socket`
listening, `/run/user/1000/{bus,pipewire-0,pipewire-0-manager}` present. `pipewire.service`
and `wireplumber.service` are correctly *inactive* until a client connects
(`wireplumber.service` is `WantedBy=pipewire.service`, and `pipewire.service` is
socket-activated); `pw-cli info 0` triggers the whole chain and both go active.
PipeWire 1.6.0 answers normally.

**Fault B -- pipewire was built with no ALSA support, silently, and the cause was build
order.** With the graph finally running, `wpctl status` showed a healthy PipeWire with
**zero Devices, Sinks and Sources** -- against four working cards in
`/proc/asound/cards` (Conexant PCH, the OneLink+ dock, a USB audio device, and the C920
mic). `wireplumber`'s own log is the only place that names it:

```
wp-device: SPA handle 'api.alsa.enum.udev' could not be loaded; is it installed?
s-monitors: PipeWire's ALSA SPA plugin is missing or broken. Sound cards will not be supported
```

`/usr/lib/spa-0.2/` has `audioconvert`, `audiomixer`, `audiotestsrc`, `avb`, `control`,
`filter-graph`, `support`, `v4l2`, `videoconvert`, `videotestsrc` -- and no `alsa/`
directory at all. `hosts/laptop/manifests/blfs-pipewire.txt` confirms it was never
installed, so this is not a later deletion. `alsa-lib` is fine and present
(`libasound.so.2`, `pkg-config --modversion alsa` = 1.2.15.3, `blfs-alsa-lib` complete).

The cause is ordering: pipewire was **seq 123**, `alsa-lib` is **seq 130**
(`state/completed` confirms the real order -- pipewire at line 266, alsa-lib at 273).
Every meson `feature` option in pipewire defaults to `auto`, so it probed for an
alsa-lib that did not exist yet, disabled the ALSA SPA plugin, and installed with exit 0
and nothing in the log to read as a failure. The recipe's own header comment lists the
Recommended deps it *meant* to skip (BlueZ, gstreamer, SBC, v4l-utils); ALSA was never
one of them. Worth generalizing: this is the same shape as the gdk-pixbuf loader trap
already recorded in `blfs-overrides.json` -- an `auto` feature whose absence surfaces
only as missing behavior in an unrelated package, days later.

Fixed in the repo, two halves:

- `recipes/blfs-pipewire.sh` now pins `-D alsa=enabled` rather than leaving it `auto`,
  so a regression fails at configure time instead of shipping a mute system.
- `hosts/laptop/packages.py` moves pipewire/wireplumber to **seq 130.5/130.6**, right
  after alsa-lib. 123/124 are left as gaps with a comment explaining why, per CLAUDE.md
  -- numbers not reused, gaps kept as history. Fractional seqs rather than appending
  after 228 so pipewire stays inside Tier 11 and keeps its position relative to
  everything downstream that expects it (mpv's audio outputs ~159, the pavucontrol chain
  at 209/210). Verified: 240 entries, still sorted, no duplicate seqs.

`bluez5` is left off deliberately. It needs `sbc`, the mandatory A2DP codec, and no
`sbc` tarball is in `/sources`; whether BLFS 13.0 has a page for it could not be checked
from here (no book mirror). So Bluetooth audio is a separate step regardless -- and it
also waits on the missing `ibt-11-5.sfi` firmware from item 1.

**pipewire is therefore up but still deaf: the rebuild has not been run.** It needs the
two tarballs re-fetched first.

### 3. upower: `CONFIG_USER_NS` unset, plus the unit was never enabled

`upower.service` was `inactive (dead)` and `disabled`. Starting it by hand fails
immediately, five times, then gives up:

```
(upowerd)[926]: upower.service: Failed to set up user namespacing: Invalid argument
(upowerd)[926]: upower.service: Failed at step USER spawning /usr/libexec/upowerd: Invalid argument
systemd[1]: upower.service: Main process exited, code=exited, status=217/USER
```

`/usr/libexec/upowerd` exists and is fine -- it is never reached. upower's own upstream
unit (shipped by the package, not written here) sets `PrivateUsers=yes` in its sandbox
block, and `/boot/config-6.18.10` has `# CONFIG_USER_NS is not set`. `defconfig` leaves
it off and nothing in this project ever turned it on, so *any* unit with
`PrivateUsers=yes` dies at step USER before exec. Nothing about this is upower-specific.

Fixed by adding `$K --enable USER_NS` to `bin/kernel-config-base.sh` (shared -- see item
1), and `systemctl enable upower.service` so it comes up with `graphical.target`. **It
will keep failing until the kernel is rebuilt**; the enable is staged, not a fix on its
own. A `PrivateUsers=no` drop-in would work around it today at the cost of the unit's
sandboxing, and was deliberately not applied, since the kernel rebuild is wanted for the
webcam anyway and `USER_NS` is worth having for its own sake.

### 4. wofi: `XDG_DATA_DIRS` was missing `/usr/share`, which broke every GTK icon

wofi (seq 197, hand-authored, the SUPER+D binding) aborted hard rather than
misbehaving:

```
Gtk-WARNING: Could not load a pixbuf from /org/gtk/libgtk/icons/16x16/status/edit-find-symbolic.symbolic.png.
This may indicate that pixbuf loaders or the mime database could not be found.
Gtk:ERROR:../gtk/gtkiconhelper.c:495:ensure_surface_for_gicon: assertion failed (error == NULL):
  Failed to load /org/gtk/libgtk/icons/16x16/status/image-missing.png:
  Unrecognized image file format (gdk-pixbuf-error-quark, 3)
Bail out!  (core dumped)
```

That signature is already in this repo -- it is verbatim the crash
`recipes/blfs-overrides.json`'s `blfs-gdk-pixbuf` override was written to fix in August,
when the book's glycin-based defaults left every loader disabled. **That override is
fine and is not the problem here.** The loaders really are built: `libgdk_pixbuf-2.0.so.0`
links `libpng16.so.16` and `libjpeg.so.62` and carries the PNG/JPEG loaders' own error
strings, so png/jpeg are compiled in as built-ins, and `loaders.cache` correctly lists
the gif and librsvg svg modules.

The tell was that gdk-pixbuf could not load a **GIF** either, so this was not a
per-format loader gap. `gdk-pixbuf-pixdata` on a known-good PNG failed with "Couldn't
recognize the image file format", and `gio info` on the same file reported
`standard::content-type: application/octet-stream` -- GLib could not identify a PNG *by
magic or even by extension*. The mime database was intact (`/usr/share/mime/mime.cache`,
`globs2`, `magic` all present and populated). GLib simply was not reading it:

```
XDG_DATA_DIRS=/usr/local/share      <- /usr/share missing entirely
XDG_CONFIG_DIRS=                    <- unset
```

Cause: the live `/etc/profile` is a hand-customized copy (it references `~/Config`'s bash
files) that dropped BLFS's own "Set some defaults for graphical systems" block --
`recipes/blfs-shell-startup-files.sh` sets `XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share}`
there, and the live file has no `XDG_DATA_DIRS` line at all. `/etc/profile.d/extrapaths.sh`
then does `pathprepend /usr/local/share XDG_DATA_DIRS`, which on an *unset* variable
yields `/usr/local/share` alone. And a set-but-wrong `XDG_DATA_DIRS` is worse than an
unset one: `g_get_system_data_dirs()` honors it instead of falling back to its own
`/usr/local/share:/usr/share` default, so `/usr/share/mime` became unreachable, every
content-type lookup returned `application/octet-stream`, all gdk-pixbuf image loading
failed including its built-ins, and any GTK app drawing an icon was one icon away from
aborting. wofi was simply the first thing to actually hit it -- exactly the point the
gdk-pixbuf override's own `reason` field already makes ("nothing about that crash was
specific to the launcher").

Fixed with `/etc/profile.d/00-xdg-defaults.sh`, setting `XDG_DATA_DIRS` and
`XDG_CONFIG_DIRS` with the same `:-` defaults BLFS uses. A drop-in rather than an edit
to `/etc/profile`, for two reasons: that file is the operator's own customized copy and
not this repo's to rewrite, and the `00-` prefix guarantees it is sourced before
`extrapaths.sh` in the glob, which is what makes the `pathprepend` produce
`/usr/local/share:/usr/share` instead of clobbering. `XDG_RUNTIME_DIR` is deliberately
left out -- `start-hyprland.sh` already forces the real `/run/user/$(id -u)`, and BLFS's
`/tmp/xdg-$USER` fallback would be wrong here.

Verified: a clean login shell now gives `XDG_DATA_DIRS=/usr/local/share:/usr/share` and
`XDG_CONFIG_DIRS=/etc/xdg`; `gio info` reports `image/png`; `gdk-pixbuf-pixdata` loads
the same PNG that failed before; and **wofi launches and stays up** against the live
Wayland display (`--show drun` ran to a 6s timeout, exit 124, instead of dumping core).

**Not fixed, cosmetic, separate gap: no icon theme is installed.** wofi now runs but logs
`gtk_icon_info_load_icon: assertion 'icon_info != NULL' failed` per entry, because
`/usr/share/icons` holds only `hicolor` (with **no `index.theme`** -- just files other
packages dropped in) and `locolor`. With no theme index GTK cannot build a fallback
chain, so per-application icons resolve to nothing. `hicolor-icon-theme` and
`adwaita-icon-theme` are both real BLFS pages and neither is in `packages.py`. Two small
steps whenever icons are wanted; nothing else depends on it.

### 2026-09-04, same session: enabling linger mid-session hid the live Hyprland's sockets

Self-inflicted, found within minutes because the operator said "I can't open wofi or
alacritty", fixed without losing the session. Recording it in full because the
presentation is badly misleading and the obvious cleanup command would have destroyed
the session outright.

**What happened.** `loginctl enable-linger john`, applied above to get a user systemd
instance on a PAM-less box, pulls in `user-runtime-dir@1000.service`, whose entire job is
to mount a fresh tmpfs at `/run/user/1000`. That directory was **already populated** --
the operator's Hyprland had been running on tty2 since 08:52 and had put `wayland-1`,
`wayland-1.lock`, `hypr/`, `ssh-agent.1000.sock`, `cc-socks/` and
`Alacritty-wayland-1-567.sock` in it, via the plain directory
`/etc/tmpfiles.d/xdg-runtime-john.conf` creates. systemd mounted straight over the top.

**Why it looked like nothing was wrong.** Every existing process kept working:
Hyprland (pid 474) and the already-open alacritty (pid 567) hold open file descriptors,
which survive the shadowing fine. `Hyprland` was still in `ps`, the screen was still
live, no unit failed, and nothing was logged anywhere. Only *new* Wayland clients broke,
because `$WAYLAND_DISPLAY=wayland-1` resolves to a path that now pointed into an empty
tmpfs. So the symptom was "SUPER+D and SUPER+Return do nothing" on a compositor that
looked completely healthy -- and it arrived in the same session as a real, separately
diagnosed wofi bug (the `XDG_DATA_DIRS` crash above), which is a good way to spend a long
time fixing the wrong thing. The tell is one line: `findmnt /run/user/1000` showing a
tmpfs, plus `ls /run/user/1000` showing pipewire's sockets and *not* `wayland-1`.

**The trap in the cleanup.** The intuitive fix is `systemctl stop
user-runtime-dir@1000.service`. Do not. Its `ExecStop` is
`systemd-user-runtime-dir stop 1000`, and that does not merely unmount -- verified
empirically before touching the real session, by staging a throwaway UID 9999 (plain
dir + a marker file, tmpfs mounted over it, then `systemd-user-runtime-dir stop 9999`):
the mount went away, the directory itself was removed, and the marker file underneath it
was gone with it. On UID 1000 that would have deleted the live session's sockets and
hard-killed Hyprland.

**What was actually done**, in this order:

1. `systemctl stop user@1000.service` -- kills pipewire/wireplumber only. Checked first
   that this cannot cascade: `user@.service` is `BindsTo=user-runtime-dir@%i.service`,
   which is one-directional, and `user-runtime-dir@1000.service` has
   `StopWhenUnneeded=no` with empty `RequiredBy=`/`WantedBy=`, so nothing garbage-collects
   it.
2. `umount /run/user/1000` **by hand**, never via `systemctl stop`, so only the mount was
   removed and no `ExecStop` ran.
3. Confirmed all seven original entries came back with their original 08:52 timestamps,
   and that `Hyprland` was still pid 474.
4. Confirmed the actual user-visible fix: `alacritty -e true` exits 0, and `wofi --show
   drun` runs to its timeout instead of dumping core.

**Two guards left behind.** `user-runtime-dir@1000.service` is now `active` with nothing
mounted, which is a live hazard for the rest of this boot -- if anything stops it, it
`rm_rf`s the revealed directory. Note that `loginctl disable-linger john` would also
stop it, so *that* is not the way to back this change out before a reboot. Guarded with
`RefuseManualStop=yes` in a drop-in under **`/run/systemd/system/`** rather than `/etc`,
deliberately: it is a this-boot-only concern and vanishes at reboot, where the
unqualified ability to stop the unit is wanted back.

The second guard is in `hosts/laptop/overlay/home/john/start-hyprland.sh` (deployed
live): when `/var/lib/systemd/linger/$USER` exists, wait for `$XDG_RUNTIME_DIR` to
actually be a mountpoint before creating anything in it, bounded at ~10s and non-fatal
(warn and continue rather than refuse to start a desktop). This closes the ordering race
permanently rather than relying on it. In practice systemd wins that race easily -- the
lingering user manager starts during boot, long before anyone finishes typing a password
at the getty -- so the loop should exit on its first check.

**Net state.** Linger stays enabled: from the next boot the ordering is right by
construction (user-runtime-dir mounts the tmpfs during boot, Hyprland starts minutes
later and uses it), which is the arrangement pipewire needs. `user@1000.service` is left
**stopped for the remainder of this boot** -- restarting it would risk a remount for no
gain, since pipewire has nothing to offer until the ALSA rebuild anyway. Nothing was lost:
same Hyprland, same alacritty, same ssh-agent.

### 2026-09-04, same session: both rebuilds run -- pipewire has audio, kernel has the webcam

Operator: "do both rebuilds". Both completed, both verified. One reboot still outstanding.

**`jobs` raised 2 -> 4** (`hosts/laptop/host.toml`), operator decision, reversing the
original cap. The old comment reserved two threads to keep the daily driver usable during
a build; the operator asked for all four. Worth recording the confusion that prompted it:
`host.toml`'s `[hardware] cpu` string says "2 cores / 4 threads" and `lfshost.py` printed
`jobs=2`, which this session repeated as "2 cores -- no point contending". Both readings
are defensible and the live machine confirms both: `lscpu` reports 2 physical Skylake-U
cores with 2 threads each, and `nproc` is 4. Four schedulable CPUs is the number that
matters for `-j`. 15GiB RAM makes `-j4` safe here; qt6 remains the one package where the
lower number may still be wanted.

**Sources.** Neither tarball was in `/sources` (down to 33 files). `bin/fetch-sources.sh`
was no help -- it drives off `book/wget-list-systemd`, which needs the book (absent
natively) and covers only LFS's 92 sources, not BLFS. Fetched both from upstream
gitlab.freedesktop.org instead and verified against this repo's own stored list,
`blfs-staging/blfs-md5-pipewire`: `pipewire-1.6.0.tar.bz2` and
`wireplumber-0.5.13.tar.bz2` both `OK`. The md5 match is what makes the provenance
argument, not the URL.

**pipewire rebuild: 5.3 min, exit 0, manifest 611 files** (was 170 -- the old manifest
was itself evidence of how much had silently not been built). `-D alsa=enabled` was
confirmed present in the generated `/sources/.build/blfs-pipewire.sh` before starting,
and mid-build `ps` caught
`spa/plugins/alsa/libspa-alsa.so.p/alsa-compress-offload-device.c` compiling with
`-D HAVE_ALSA_UCM`, i.e. the fix taking effect rather than inferred after the fact. Four
concurrent `cc1` processes confirmed `-j4` was live. Result on disk:
`/usr/lib/spa-0.2/alsa/libspa-alsa.so`, linked against `libasound.so.2` and
`libudev.so.1`, recorded in the manifest.

**wireplumber deliberately NOT rebuilt.** It was queued for a rebuild on the assumption
it shared pipewire's problem, since it was seq 124 and also ahead of alsa-lib. Checked
instead of assuming: `ldd /usr/bin/wireplumber` has **zero** `libasound` references.
Wireplumber never links ALSA -- it consumes pipewire's SPA plugins at runtime, so
pipewire's rebuild is the whole fix and rebuilding wireplumber would have been busywork.
Its seq still moved to 130.6 so a fresh build orders correctly.

**Audio verified working**, and the first attempt at verifying it was wrong in a way
worth writing down. Starting `pipewire`/`wireplumber` by hand still showed zero devices,
with wireplumber's ALSA complaint now gone (only the harmless libcamera one left). Cause
was the test, not the build: `usermod -a -G audio john` had run earlier in this session,
but **this shell's supplementary groups were fixed at its own login, before that** --
`id -G` showed no gid 11, and `/dev/snd/controlC1` was genuinely unreadable by it. The
systemd-started instance from earlier had `Groups: 11 ...` and would have been fine. Re-run
under `sg audio`, and:

- 4 Devices: Built-in Audio (Conexant PCH), ThinkPad OneLink Plus Dock Audio, Audio
  Adapter (Unitek Y-247A), HD Pro Webcam C920
- 3 Sinks, 4 Sources, all `[alsa]`
- with `pipewire-pulse` also started, `pactl info` reports "PulseAudio (on PipeWire
  1.6.0)", server version 15.0.0 -- which is what pavucontrol talks to, so the original
  "pavucontrol shows no devices" report is now addressed at the root

Those three daemons are running by hand for the rest of this boot (audio works now); from
the next boot the systemd user units take over, which is the supported path.

**A stale-staging trap caught before the kernel build, not after.** `/sources/kernel-config.sh`
and `/sources/kernel-config-base.sh` are *copies*, staged separately from the repo, and
both were out of date: the base was missing `USER_NS` (added this session, expected) and
the host file was missing the **entire UVC/media section** -- which the previous session
had written to the repo and described as "pushed to this host", but which had never been
re-staged into `/sources`. Building without checking would have produced a kernel with
neither fix and looked like a successful rebuild. Both re-staged and diffed byte-equal
against the repo before starting. Standing lesson: `/sources/kernel-config*.sh` are not
the repo's files, and `diff` against the repo is a required pre-flight step for any kernel
rebuild.

**Boot-path safety, before touching anything.** All these kernels are version 6.18.10 --
the string never changes between rebuilds -- so they share one `/lib/modules/6.18.10`,
and `make modules_install` overwrites it in place. Backed up as `.preUVC`:
`/boot/vmlinuz-6.18.10-lfs-13.0-systemd.preUVC` (md5-verified identical to the running
kernel at the time), the matching `System.map`/`config`, and a full copy of the modules
tree at `/lib/modules/6.18.10.preUVC` (21MB). `/boot/grub/grub.cfg` gained a
"pre-webcam/USER_NS fallback (2026-09-04)" entry alongside the existing pre-Bluetooth
one, every referenced vmlinuz confirmed present on disk, and the old file kept as
`grub.cfg.bak-2026-09-04`. `grub.cfg` was also **untracked** until now -- it is now in
`hosts/laptop/overlay/boot/grub/grub.cfg`, matching the convention `server` already
follows, with a comment explaining the shared-modules-tree restore procedure.

**Kernel rebuild: 23.0 min, exit 0.** `cp -iv` was not an issue -- `hosts/laptop/review-overrides.json`
already replaces blocks 5/6/7 with non-interactive `cp -v`. Verified on disk afterwards:

- `/boot/vmlinuz-6.18.10-lfs-13.0-systemd` rebuilt at 10:08, 12,829,696 bytes, md5
  distinct from the `.preUVC` backup (so the copy really happened -- worth checking given
  the `cp -i` history)
- `/boot/config-6.18.10`: `USER_NS=y`, `MEDIA_SUPPORT=y`, `MEDIA_USB_SUPPORT=y`,
  `MEDIA_CAMERA_SUPPORT=y`, `MEDIA_CONTROLLER=y`, `USB_VIDEO_CLASS=m`,
  `VIDEOBUF2_{CORE,V4L2}=m`, `BT=m` still intact
- `/lib/modules/6.18.10/kernel/drivers/media/usb/uvc/uvcvideo.ko` plus the four
  `videobuf2-*.ko` helpers, and `btusb.ko`/`bluetooth.ko` still present

One deviation from what was asked for: `VIDEO_DEV` came out `=y`, not `=m`. Kconfig
promotes it because `MEDIA_SUPPORT=y` plus the enabled sub-menus select it as builtin.
Harmless -- it is the V4L2 core, not a driver, nothing here is on the boot path -- and now
recorded in `hosts/laptop/kernel-config.sh`, which had explicitly asked for this to be
verified rather than assumed. The auto-selected symbols (`MEDIA_CONTROLLER`,
`VIDEOBUF2_*`) did resolve on their own, as that comment predicted.

Watch for one thing while reading `.config` mid-build: an intermediate read showed
`USER_NS=y` but `# CONFIG_MEDIA_SUPPORT is not set`, which looks like the host section
failing. It was just a race -- `kernel_config_shared` (the base, with `USER_NS`) runs
before the host additions, so the file is legitimately half-written for a while. Re-read
after the config stage finished and everything was set.

`bin/lfsmaint db` re-run afterwards, per PRACTICES' maintenance cadence: 346 packages,
109,430 files.

**Still outstanding.**

1. **A reboot** -- the running kernel is still the old one, so the webcam has no
   `/dev/video*` and `upower.service` still fails at `217/USER`. Both are fixed in the
   kernel on disk and neither can be tested before rebooting. `modprobe uvcvideo` was not
   attempted: the new modules were built against a kernel whose `VIDEO_DEV` is builtin and
   the running kernel has no media subsystem at all, so it would fail on missing symbols
   for no information gained.
2. `intel/ibt-11-5.sfi` firmware -- unchanged by either rebuild, still the reason
   Bluetooth has a bound `hci0` and no usable adapter.
3. `hosts/laptop/state/blfs-plan.json` still lists pipewire/wireplumber at the old seq
   123/124. It is generated by `extract-blfs.py`, which needs the book, so it cannot be
   regenerated on this host -- harmless for the `--only` rebuilds run here (same step
   name, tarball and recipe), but it must be regenerated from a checkout that has the
   books before the next real extraction, or a fresh build will use the old order.
4. `hicolor-icon-theme` + `adwaita-icon-theme` (wofi icons), and `sbc` (Bluetooth audio,
   also gated on 2).

### 2026-09-04, same session: firmware, sbc + Bluetooth audio, icon themes

Operator: "before I reboot lets get the firmware and sbc built, sure get wofi icons as
well". All three done, four new steps, all verified. Nothing here needed the reboot to
build; two of the three need it to take effect.

**Four new steps** (`hosts/laptop/packages.py`):

| seq | step | source | note |
|-----|------|--------|------|
| 130.3 | `sbc` | kernel.org bluetooth dir, sha256 in recipe | shared recipe, no BLFS page |
| 229 | `hicolor-icon-theme` | freedesktop.org, 0.18 | shared; BLFS *has* a page, hand-authored only because no book mirror here |
| 230 | `adwaita-icon-theme` | download.gnome.org, 49.0 | ditto |
| 231 | `linux-firmware-intel-bluetooth` | LFS mirror | host-specific -- names one chip |

**The bluez5 ordering problem, and a misread caught by checking.** pipewire's `bluez5`
feature was initially assumed to need only `sbc`, on the strength of this line in
`spa/plugins/bluez5/meson.build`:

    cdata.set('HAVE_BLUEZ_5_HCI', dependency('bluez', version: '< 6', required: false).found())

`required: false` -- so bluez looked optional, and the plan was to leave it at seq 224
behind pipewire's 130.5. That was **wrong**. The actual dependency gate is in
`spa/meson.build`:

    bluez_dep = dependency('bluez', version : '>= 4.101', required: get_option('bluez5'))
    sbc_dep   = dependency('sbc', required: get_option('bluez5'))
    bluez5_deps = [ mathlib, dbus_dep, sbc_dep, bluez_dep, bluez_glib2_dep,
                    bluez_gio_dep, bluez_gio_unix_dep ]
    foreach dep: bluez5_deps
        if get_option('bluez5').enabled() and not dep.found()
          error('bluez5 enabled, but dependency not found: ' + dep.name())

Under `-D bluez5=enabled` every one of those is required and a miss is a hard configure
error. The `required: false` probe only sets `HAVE_BLUEZ_5_HCI`; it is not the gate. So
bluez behind pipewire would not have been a silent downgrade, it would have failed the
build outright.

Fixed by moving **libical 223 -> 130.1** and **bluez 224 -> 130.2**, ahead of sbc at
130.3 and pipewire at 130.5. Checked before moving that this drags nothing else along:
libical needs only cmake (17), glib2 (29), icu (30), libxml2 (69); bluez needs glib2,
dbus (101) and libical. 223/224 left as documented gaps, numbers not reused. Codecs past
SBC (LDAC, aptX, LC3, FDK-AAC) stay on their own `auto` options -- that is the case `auto`
is genuinely for, since their absence costs codec choice on a connected device, not
Bluetooth audio itself.

**`blfs-plan.json` had to be hand-edited, and that is worth flagging.** `lfsbuild` refused
every new step with `no such step: blfs-sbc` -- the plan is generated by
`extract-blfs.py`, which needs the book, which is absent natively. Hand-added the four
entries (schema copied from the existing `hand()` firmware entries) and re-seq'd
libical/bluez/pipewire/wireplumber to match `packages.py`, then asserted the result is
sorted with unique seqs and names, and cross-checked every name/seq against `packages.py`
(zero mismatches). Backup at `scratchpad/blfs-plan.json.bak`. This is state, not a
generated recipe, so editing it is legitimate -- but it is still a generated file, and the
real regeneration from a checkout with the books is still owed.

**Build results**, all exit 0: sbc 0.1 min (9 files), pipewire 4.7 min (517 files),
hicolor 0.0 min (2 files), adwaita 0.0 min (833 files), firmware 0.0 min (2 files).

`/usr/lib/spa-0.2/bluez5/` now holds `libspa-bluez5.so` plus nine codec plugins -- SBC,
AAC, Opus, Opus-G, G.722, faststream, HFP CVSD, HFP mSBC -- with
`libspa-codec-bluez5-sbc.so` linked against `libsbc.so.1`. AAC and Opus came for free
because fdk-aac and opus were already built. ALSA plugin still in place; `wpctl status`
still lists all 4 cards, 3 sinks, 4 sources, and wireplumber's log now has no bluez
complaint at all (only the harmless libcamera one).

**A manifest scare that turned out to be nothing.** pipewire's manifest went 611 -> 517
files across the two rebuilds, which is the wrong direction when a feature is being added.
Checked rather than assumed: enumerated every file on disk under
`/usr/share/pipewire`, `/usr/include/pipewire-0.3`, `/usr/include/spa-0.2`,
`/usr/lib/spa-0.2` and `/usr/lib/pipewire-0.3` -- 326 files, **0 missing from the
manifest**. The 611 run had simply also swept up incidental files whose ctime moved for
unrelated reasons. `lfsmaint db` now reports 350 packages / 110,182 files, and `lfsmaint
owns` attributes each new file correctly (bluez5 plugin -> pipewire-1.6.0, libsbc ->
sbc-2.1, both index.theme files -> their own themes, ibt-11-5.sfi ->
linux-firmware-intel-bluetooth).

**Firmware verified working without waiting for the reboot.** Forced a re-probe of just
the Bluetooth USB interface (`unbind`/`bind` on `/sys/bus/usb/drivers/btusb`) rather than
`modprobe` -- deliberately, because the on-disk modules are now the *new* kernel's and the
running kernel is the old one, so a module reload could hit symbol mismatches for no
benefit. dmesg is unambiguous:

    Bluetooth: hci0: Found device firmware: intel/ibt-11-5.sfi
    Bluetooth: hci0: Firmware loaded in 1809275 usecs
    Bluetooth: hci0: Device booted in 12055 usecs
    Bluetooth: hci0: Found Intel DDC parameters: intel/ibt-11-5.ddc
    Bluetooth: hci0: Applying Intel DDC parameters completed
    Bluetooth: hci0: Firmware revision 0.0 build 14 week 44 2021

`Failed to load ... (-2)` is gone, and **both** blobs were used -- which settles the
judgement call to fetch the `.ddc` alongside the `.sfi`.

The adapter still does not register with bluetoothd: `bluetoothctl list`/`show` are empty,
`/sys/class/bluetooth/hci0/` has no `address` attribute, and dmesg ends with `Reading
supported features failed (-16)` (EBUSY). Read as an artifact of the mid-session rebind,
not a firmware fault: HCI setup aborts partway, so no adapter index is ever exposed for
`bluetoothd`'s mgmt interface to pick up. A second clean unbind/bind cycle reported the
firmware revision directly without re-downloading (Intel parts keep firmware resident
until a power cycle), i.e. the blob is loaded and the chip simply needs a cold init.
Symptom is identical to before this step, so nothing regressed; the reboot exercises the
real path. Stopped there rather than keep cycling USB on a live desktop.

**Icons fixed.** `/usr/share/icons` had only `hicolor` **without an index.theme** (just
loose files other packages dropped in) plus `locolor`; with no theme index GtkIconTheme
cannot build a lookup or fallback chain, so every icon name resolved to nothing. Now
Adwaita 49.0 (801 files, own `icon-theme.cache`) and hicolor 0.18 with a real
`index.theme`. Both caches regenerated with `gtk-update-icon-cache -f` afterwards, since
hicolor's existing cache (owned by gtk-4.20.3) predated its new index. Verified: wofi's
`gtk_icon_info_load_icon: assertion 'icon_info != NULL'` count went from one-per-entry to
**0**.

Adwaita pinned to 49.0 rather than newest: this build is GNOME 49
(gsettings-desktop-schemas 49.1), and 49.1 of the icon theme does not exist upstream
(download.gnome.org 404s; 49.0 is the only 49-series release) -- checked, not assumed.

**A latent hazard found and avoided, worth fixing elsewhere.** This host's two existing
firmware recipes (`blfs-linux-firmware-iwlwifi-8260.sh`, `-i915-dmc.sh`) and nine shared
recipes carry a chroot-era `/etc/resolv.conf` fix whose exit trap ends with
`ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf`. On this machine
`/etc/resolv.conf` is a **regular file** (`nameserver 1.1.1.1` / `8.8.8.8`), so running any
of them natively would silently replace it with a symlink -- an unrequested change to the
live host's network config as a side effect of a build step. Not fatal here
(systemd-resolved is active with those same upstreams configured, so DNS would still
resolve), but wrong. The new firmware recipe omits the block entirely and says why in a
comment. The other eleven recipes still have it and should get a native-mode guard before
any of them is re-run on a live host.

**wofi "stopped opening" mid-session -- not a regression.** Reported right after the icon
work. Reproduced both ways: in a clean login shell wofi runs to its timeout (exit 124,
stays up); in the *running* Hyprland session's environment it still dies with the original
`Gtk:ERROR ensure_surface_for_gicon` / "Unrecognized image file format" core dump. The
session started 08:52, the `XDG_DATA_DIRS` drop-in was written 09:07, and a login shell's
environment is fixed at login -- so that session has carried the broken
`XDG_DATA_DIRS=/usr/local/share` the whole time and always would. Nothing in the icon or
cache work caused it, and no live fix is possible for an already-running session. The
reboot resolves it by giving Hyprland a fresh login shell that sources
`/etc/profile.d/00-xdg-defaults.sh`.

**Reboot readiness, checked immediately before handing back.** grub `default=0` points at
the freshly built kernel (10:08, 12,829,696 bytes) with all three referenced vmlinuz files
present; `root=PARTUUID=f1183155-01` matches `lsblk`'s actual PARTUUID for nvme0n1p1;
`/boot/config-6.18.10` carries all three target options; the live modules tree has 90
modules including `uvcvideo.ko` with the 84-module `.preUVC` backup intact; no build in
flight; 27G free.

**Mistake made and corrected: a shared generated recipe was clobbered.**
`recipes/blfs-hicolor-icon-theme.sh` was written from scratch here as a "HAND-AUTHORED"
file -- but it already existed, as a **book-extracted candidate** (its header names
`book/blfs-13.0/x/hicolor-icon-theme.html`) that `server` has been building since its own
wofi debugging, at server's seq 208, with a manifest to prove it. Overwriting it was wrong
on both counts CLAUDE.md warns about: it edits a generated recipe in place, so `--check`
would report drift and the next extraction would discard the edit, and it silently changes
a recipe a *different host* depends on. Caught only because `git diff --stat` showed the
file as modified rather than new -- the Write tool reporting "updated" rather than
"created" was the signal, and it was missed at the time.

Reverted with `git checkout --`, verified byte-identical to HEAD. The laptop entry is now
`book(229, "hicolor-icon-theme", "x/hicolor-icon-theme.html", ...)`, with the page path
read off the recipe's own source line. No functional difference to what got installed:
both versions run the same `meson setup --prefix=/usr --buildtype=release` and
`ninja install` against the same 0.18 tarball, and `lfsmaint owns` confirms
`/usr/share/icons/hicolor/index.theme` is attributed to hicolor-icon-theme-0.18.
Adwaita was checked the same way and is genuinely new (no recipe, no manifest, absent from
server's packages.py), so it stays `hand()`.

Two smaller corrections from the same review: `blfs-plan.json` was first rewritten with
`json.dump(indent=1)`, which re-diffed all 6776 lines of a generated file for no reason --
`bin/extract-blfs.py` uses `indent=2`, so it was rewritten to match and the diff dropped to
the 112/56 lines actually changed. And the `blocks`/`enabled`/`disabled` metadata on the
four hand-added plan entries is approximate (1/1/0); it is derived from the book by the
extractor and will be corrected whenever the plan is properly regenerated.

### Live state at the end of this session (pre-reboot)

Everything the operator asked for across this session is built and on disk. The machine
has **not** been rebooted; three of the fixes cannot take effect until it is.

Working right now, no reboot needed:

- **Audio.** pipewire 1.6.0 with the ALSA SPA plugin and the bluez5 plugin (nine codecs).
  `wpctl status`: 4 devices, 3 sinks, 4 sources. `pactl info` reports "PulseAudio (on
  PipeWire 1.6.0)", so pavucontrol works. Running as three hand-started daemons for this
  boot only (`pipewire`, `wireplumber`, `pipewire-pulse`, launched under `sg audio`);
  systemd's user units take over at next boot.
- **Icon themes.** hicolor 0.18 + Adwaita 49.0 installed, both caches regenerated.
- **Bluetooth firmware.** `intel/ibt-11-5.sfi` + `.ddc` installed and proven to load
  (dmesg: "Firmware loaded in 1809275 usecs", "Applying Intel DDC parameters completed").
- **wofi** launches and stays up in a *clean login shell*. It still dies in the currently
  running Hyprland session, which has carried the broken `XDG_DATA_DIRS` since 08:52 --
  see the note above; only a fresh login fixes that, so the reboot is the fix.

Needs the reboot to take effect:

1. **Webcam** -- `uvcvideo.ko` is installed but the running kernel has no media subsystem,
   so there is still no `/dev/video*`.
2. **`upower.service`** -- enabled, and still failing `217/USER` until the running kernel
   has `USER_NS`.
3. **Bluetooth adapter** -- firmware loads, but HCI setup aborts after a mid-session USB
   rebind (`Reading supported features failed (-16)`, no `address` in
   `/sys/class/bluetooth/hci0/`), so no adapter reaches bluetoothd. Needs a cold init.
4. **wofi in the operator's own session**, per above.
5. **pipewire under systemd** -- linger + the `user@.service` drop-in are in place; at next
   boot `user-runtime-dir@1000.service` mounts `/run/user/1000` during boot, before
   Hyprland starts, which is the ordering the linger incident above was caused by not
   having.

Live-only changes (not in the repo, would need reapplying on a rebuild):
`/etc/profile.d/00-xdg-defaults.sh`, `/etc/systemd/system/user@.service.d/10-no-pam-runtime-dir.conf`,
`loginctl enable-linger john`, `john` added to group `audio`, `systemctl enable upower.service`.
`/boot/grub/grub.cfg` is now tracked at `hosts/laptop/overlay/boot/grub/grub.cfg`.
`/etc/profile` itself was left untouched.

**Until the reboot**: do not stop `user-runtime-dir@1000.service` and do not run
`loginctl disable-linger john` -- either would `rm_rf` the live session's
`/run/user/1000`. Guarded with `RefuseManualStop=yes` in `/run/systemd/system/` (which
evaporates at reboot, as intended).

### Verify after the reboot

    ls /dev/video*                       # webcam -- expect video0/video1
    systemctl status upower.service      # expect active, not 217/USER
    bluetoothctl list                    # expect a real controller at last
    wpctl status                         # audio, now via systemd user units
    systemctl --user status pipewire.socket wireplumber.service
    loginctl list-sessions               # still "No sessions" -- expected, no PAM
    findmnt /run/user/1000               # SHOULD be a tmpfs now, and that is correct
    echo $XDG_DATA_DIRS                  # expect /usr/local/share:/usr/share
    # then SUPER+D for wofi, with icons

### Still owed

- **`hosts/laptop/state/blfs-plan.json` was hand-edited** (four new steps added, four
  re-seq'd) because `extract-blfs.py` needs the book, which is absent in native mode.
  Regenerate it, plus run `extract-recipes.py --check` / `extract-blfs.py --check`, from a
  checkout that has the books. Zero drift is the expected state and was never confirmed
  this session.
- **Eleven recipes carry a chroot-era `/etc/resolv.conf` rewrite** that would clobber a
  live host's regular-file `resolv.conf` with a symlink. Needs a native-mode guard.
- **`hosts/laptop/CLAUDE.md` is stale** beyond the `jobs` line corrected here: it still
  opens with "Not built yet" and "`packages.py` is still `BASE` alone", against 244
  entries and ~44h of build time.
- Nothing in this session was committed. `git fetch` confirmed `HEAD == origin/main`
  (0 ahead, 0 behind) before any of the work started.

## 2026-09-04 -- post-reboot verification

Booted `vmlinuz-6.18.10-lfs-13.0-systemd` (GRUB entry 0) at 10:50 CDT. All five items
from the previous session's "Verify after the reboot" list pass.

- **Webcam.** `/dev/video0`, `/dev/video1`, `/dev/media0`. `uvcvideo` bound to the Chicony
  `Integrated Camera` (04f2:b531) as a UVC 1.00 device. The config delta against
  `config-6.18.10.preUVC` is exactly the media subsystem plus `CONFIG_USER_NS=y` -- 23
  symbols, nothing incidental.
- **upower.** `active (running)` since 10:50:56, PID 329. The `217/USER` failure is gone,
  as predicted, once `USER_NS` was in the running kernel.
- **Bluetooth adapter.** Cold init works. `intel/ibt-11-5.sfi` loads in 1.73 s,
  `ibt-11-5.ddc` applies, firmware revision 0.0 build 14 week 44 2021. Controller
  `44:85:00:11:35:9F` reaches bluetoothd, powers on, takes the name `laptop`, and
  registers GAP/GATT/DIP/AVRCP/AVRCP-Target/DIS UUIDs on `/org/bluez/hci0`. Settings read
  back `Secure Simple Pairing, BR/EDR, Low Energy, Secure Connections, Wideband Speech`.
  Two dmesg lines survive and are both benign: `Reading supported features failed (-16)`
  is `btintel_read_debug_features` on a production-locked part (Debug lock disabled, API
  lock enabled), and `HCI LE Coded PHY feature bit is set, but its usage is not supported`
  is an informational kernel notice. Neither blocks setup -- verified by `btmon` capture of
  a full `systemctl restart bluetooth` cycle.
  Note for future sessions: `bluetoothctl show` / `bluetoothctl list` print **nothing** when
  stdin is not a tty (bluez 5.86 single-shot mode), which reads as "no controller" and is
  not. Use `printf 'show\nquit\n' | bluetoothctl`, or `busctl --system introspect org.bluez
  /org/bluez/hci0 org.bluez.Adapter1`, which is unambiguous.
- **Audio under systemd.** `pipewire.socket` and `pipewire-pulse.socket` enabled and
  listening; `wireplumber.service` enabled. `wpctl status`: 3 ALSA devices (Built-in
  CX20753/4, ThinkPad OneLink Plus Dock, Unitek Y-247A), 3 sinks, 3 sources, plus the
  Integrated Camera as a V4L2 source. pavucontrol was already running in the operator's
  session with live streams on all three. All nine `libspa-codec-bluez5-*.so` present.
  One trap worth writing down: `wpctl status` run at the instant it socket-activates
  pipewire returns an empty graph, because the first call *is* what starts the daemon and
  wireplumber has not enumerated yet. It is a race in the measurement, not a fault. Give
  it a second, or start the units explicitly first.
- **Session plumbing.** `loginctl list-sessions` -> "No sessions" (expected, no PAM);
  `loginctl list-users` shows john `lingering`; `/run/user/1000` is a tmpfs mounted at
  boot; `XDG_DATA_DIRS=/usr/local/share:/usr/share` in both a login shell and PID 523's
  (Hyprland's) environ. `wofi --show drun` stays up. Its earlier "dies immediately" was
  reproduced and explained: it exits 1 with no message when `WAYLAND_DISPLAY` is unset,
  which is what a bare non-session shell looks like.

Rest of the machine: `systemctl is-system-running` -> `running`, zero failed units system
and user. Hyprland 0.56.2 on i915 with `skl_dmc_ver1_27.bin` loaded; eDP-1 connected but
disabled (lid), DP-3 and DP-5 active on the dock. eth0 DHCP 192.168.0.210, wg0 up, DNS
resolves. Swap active on nvme0n1p2, `/` 43% used.

### Two gaps this reboot exposed

1. **thermald is running but blind.** It logs `NO RAPL sysfs present`, `Thermal DTS: No
   coretemp sysfs found`, and `Thermal DTS or hwmon: No Zones present Need to configure
   manually`, then falls back to polling mode 4 with nothing to act on. The kernel has
   `CONFIG_THERMAL`, `CONFIG_ACPI_THERMAL`, `THERMAL_HWMON` and `X86_PKG_TEMP_THERMAL=m`
   (loaded, giving `thermal_zone1`), but is missing `CONFIG_SENSORS_CORETEMP` (per-core
   DTS, thermald's primary sensor), `CONFIG_POWERCAP` + `CONFIG_INTEL_RAPL` (no
   `/sys/class/powercap` at all, so thermald's primary control knob does not exist), and
   `CONFIG_INTEL_POWERCLAMP` (idle-injection cooling device). The machine is not at risk --
   the package's own hardware throttling is unconditional, and acpitz trip points drive the
   four `Processor` cooling devices through the step_wise governor -- but thermald as
   installed cannot do its job. Fix belongs in `hosts/laptop/kernel-config.sh`, not the
   shared base: it names a CPU vendor.
2. **`regulatory.db` is absent.** `faux_driver regulatory: Direct firmware load for
   regulatory.db failed with error -2` at 0.35 s. wireless-regdb is in neither
   `packages.py` nor `blfs-plan.json`. Not biting yet -- wlp4s0 is DOWN and the box is on
   dock ethernet -- but iwlwifi will fall back to the world-roaming domain the first time
   WiFi is actually used, losing channels and tx power the local domain allows.

Unchanged known items: microcode still 0xc6 with `old_microcode: Vulnerable` (plus
`mds`/`taa`/`mmio_stale_data`/`srbds`/`gds`/`vmscape` wanting a newer revision) -- the
early-load initrd is still owed, per `host.toml`. The Synaptics touchpad still runs the
PS/2 protocol; the kernel's suggestion of `MOUSE_PS2_SYNAPTICS_SMBUS` + `RMI4_SMB` is
untested here.

## 2026-09-04 -- thermald sensors, wireless-regdb, microcode initrd, pass-otp, Noto Symbols 2

Six operator-requested items, all built. Three of them do nothing until the machine is
rebooted into the kernel this session produced; the other three are live now.

### thermald: two separate faults, both fixed

**The kernel had none of thermald's sensors or knobs.** Added to
`hosts/laptop/kernel-config.sh`, each symbol read out of this kernel's own Kconfig
(extracted from `linux-6.18.10.tar.xz`) rather than assumed:

- `SENSORS_CORETEMP=m` -- per-core DTS, thermald's primary input, and literally the
  `Thermal DTS: No coretemp sysfs found` line.
- `POWERCAP=y` -- the menuconfig gate `INTEL_RAPL` lives inside, and what creates
  `/sys/class/powercap`, which did not exist at all.
- `INTEL_RAPL=m` -- Running Average Power Limit via MSR, thermald's primary control knob
  and the `NO RAPL sysfs present` line. It pulled in `INTEL_RAPL_CORE=m`.
- `INTEL_POWERCLAMP=m` -- idle-injection cooling device. It pulled in `IDLE_INJECT=y`.
- `INTEL_TCC_COOLING=m` -- checked before including rather than added hopefully:
  `drivers/thermal/intel/intel_tcc_cooling.c` matches on an explicit CPU list and
  `X86_MATCH_VFM(INTEL_SKYLAKE_L)` is in it, which is what this 0x6:4e:3 part is.

Post-build `/boot/config-6.18.10` differs from its `.preTHERMAL` backup by exactly those
seven symbols and nothing else, and `/lib/modules/6.18.10` gained `coretemp.ko`,
`intel_rapl_common.ko`, `intel_rapl_msr.ko`, `intel_powerclamp.ko` and
`intel_tcc_cooling.ko`.

**thermald was also installed into `/usr/etc`.** `recipes/blfs-thermald.sh` configured
with `--prefix=/usr` and no `--sysconfdir`, so autoconf's `${prefix}/etc` default put
`thermal-cpu-cdev-order.xml` and `thermald-features.xml` in `/usr/etc/thermald/` and
compiled that path in as `TDCONFDIR`. Self-consistent, so nothing was broken -- but
`/usr/etc` was a directory no other package on this system creates, and an
operator-written `thermal-conf.xml` dropped in `/etc/thermald` would have been silently
ignored. Recipe now passes `--sysconfdir=/etc`; rebuilt, `strings` on the new binary
resolves only `/etc/thermald`, the two data files are byte-identical to the ones they
replace, and the stale `/usr/etc` tree is gone. Shared recipe, but `server` does not
build thermald, so laptop is the only consumer.

### wireless-regdb 2026.09.03 (new, shared, seq 232)

`faux_driver regulatory: Direct firmware load for regulatory.db failed with error -2` at
0.35 s of every boot, on both hosts, since forever. Installed
`/usr/lib/firmware/regulatory.db{,.p7s}` plus both man pages.

Not `make install`: the Makefile's `regulatory.bin` rule lists `$(REGDB_PRIVKEY)` as a
prerequisite whose own rule is `openssl genrsa`, so make will quietly mint a throwaway
key and re-sign the database with it -- which is exactly what a kernel built
`CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=y` refuses. It would also have created a
`/usr/lib/crda` for a userspace helper this system does not have. The recipe installs the
prebuilt upstream-signed pair directly and verifies them the way the kernel will:
`regulatory.db.p7s` validates over `regulatory.db`, and the signing certificate's
SHA-256 fingerprint is compared against the two the kernel compiles in
(`net/wireless/certs/sforshee.hex` and `wens.hex`). It came back `wens`,
`EE:B0:49:...:0B:CF`, matching byte for byte. Tarball sha256 checked against kernel.org's
`sha256sums.asc` first.

Still unverified end-to-end: nothing has re-triggered a regdb load, because `wlp4s0` is
down and `iw` is not installed. The signature chain check above is the same test the
kernel runs, so the remaining unknown is only whether the file is found -- confirm from
`dmesg` after the reboot.

### intel-microcode (new, host-specific, seq 235)

Closes the item `host.toml` has carried since 2026-08-28. Blob `06-4e-03` from Intel's
`microcode-20260812`, whose own releasenote lists it as `SKL-U/Y D0 06-4e-03/c0` at
revision `0xf0` -- this part is running `0xc6`. `CONFIG_MICROCODE=y` was already on from
defconfig, checked *before* the thermal rebuild rather than discovered after, so no
second kernel build was needed. `/boot/microcode.img` is a 105 KB cpio carrying one file.

Two deliberate departures from `server`'s copy of this recipe:

- The grub wiring is per-menuentry and idempotent per entry, in python rather than
  `sed`. This `grub.cfg` has four entries (current kernel plus three fallbacks) and all
  four want the microcode; `server`'s single `grep -q` guard is all-or-nothing and would
  skip every entry once any one of them had the line. The inserted line also copies the
  indentation of the `linux` line above it, so it matches this file's 4-space style.
- It works in a `mktemp -d` with a cleanup trap. This step's plan entry has `tarball=""`,
  so the driver has nothing to unpack, no source directory to `cd` into, and the recipe
  runs in whatever directory `lfsbuild` was invoked from. The first run left an 18 MB
  `microcode-src/` and an `initrd/` untracked in the repo checkout. `server`'s copy has
  the same exposure and has simply never been run from a checkout.

### oath-toolkit 2.6.14 + pass-otp 1.2.0 (new, shared, seq 233-234)

TOTP/HOTP out of the existing `pass` store. oath-toolkit is a hard dependency, not a
recommendation -- `otp.bash` shells out to `oathtool` for every code and names no other
program except `which`. Built `--disable-pam` (this system has no Linux-PAM at all) and
`--disable-pskc` (an XML key-provisioning format with no consumer here, and the only
thing that would have pulled libxml2 into the link). The recipe asserts RFC 4226
appendix D's own vector -- counter 0 over the standard seed must be `755224` -- so a
miscompile fails the build instead of producing wrong codes silently.

One write-up correction worth recording: `PASSWORD_STORE_ENABLE_EXTENSIONS=true` is
**not** needed for a system-wide extension, contrary to most pass-otp instructions. The
installed `/usr/bin/pass` sets `system_extension` from `SYSTEM_EXTENSION_DIR`
unconditionally and gates only `user_extension` (the per-store `.extensions` copy) behind
that variable. A `/etc/profile.d` drop-in was written on that assumption and removed once
the source was actually read. `pass otp` works with no environment change.

Provenance: oath-toolkit's detached signature is a good signature from
`Simon Josefsson <simon@josefsson.org>`. pass-otp publishes no signature, so the check is
its sha256 against Arch's own PKGBUILD, which matches.

### Noto Sans Symbols 2 v2.008 (new, shared, seq 236)

Third font here, and the first non-text face. What it adds was measured, not asserted --
differencing `fc-query` charsets across every installed font: 2953 codepoints in the
face, 1327 already covered, **1626 new**. The obvious pitch for this font is wrong and
the recipe says so: DejaVu Sans already has Braille, playing cards and the basic chess
pieces. The real gaps are legacy computing (block sextants/octants, `U+1FB00-1FBCA`, the
largest single block at 202), extended and fairy chess, non-emoji pictographs,
astronomical symbols, Mahjong tiles, clock faces, Greek acrophonic numerals and the
Phaistos Disc.

`full/ttf` of the four variants shipped: `hinted` and `unhinted` are byte-identical to
each other and 314 codepoints short, which would have quietly reintroduced the tofu the
font is meant to remove.

Two things the first attempt got wrong, both fixed: the verification used `fc-match`,
which always answers with *some* family because it falls back, and duly reported
`DejaVu Sans` for a codepoint DejaVu does not have. `fc-list ':charset=X'` lists only
fonts that really contain it, and now reports `Noto Sans Symbols 2` as the sole provider
of `U+1FB00`, `U+1FA00` and `U+1F000`. Staged as `.tar.gz` because `lfsbuild`'s unpack is
a plain `tar -xf` with no zip path, and this release's zip has no single top-level
directory for `srcdir_of()` to find -- same repack `JetBrainsMono-2.304.zip` already got.

### Two process failures from this session

**The 22 minutes that built nothing.** `ch10-kernel` runs `bash /sources/kernel-config.sh`,
and nothing in `bin/` stages that file -- it is copied there by hand. The first thermal
rebuild ran against a copy three days stale and produced a `/boot/config-6.18.10`
byte-identical to the one it replaced, reporting `OK` throughout. Written up in
`PRACTICES.md` with the cheap detection: grep the *build tree's* `.config` a minute in,
not `/boot/config-*` afterwards. The real fix -- `lfsbuild` staging the pair itself and
refusing to run on a `/sources` copy that differs from the repo -- is not done.

**`git checkout` on `blfs-plan.json` discarded last session's uncommitted edits.** Run
while adding the wireless-regdb entry, to undo a sort that had reordered the file. The
file had been hand-edited last session and never committed, so there was no blob to
recover from and no backup anywhere on disk. Reconstructed from `packages.py`, which
determines every field: the four re-seq'd steps (`libical` 130.1, `bluez` 130.2,
`pipewire` 130.5, `wireplumber` 130.6) keep their existing entries with only `seq` and
`order` changed, and the four added steps plus the new ones are rebuilt from their
`hand()`/`book()` declarations. Verified against the three entries dumped verbatim
earlier in the same session (229/230/231) and against the `libical` block visible in the
pre-revert diff -- all identical. `sbc`'s 1/1/0 block metadata is the approximate value
last session already documented. **The lesson is narrower than "don't use git checkout":
this repo carries live state as uncommitted working-tree files for days at a time, so
any destructive git operation here needs the same care as `rm`.**

### enchant 2.8.21 + hunspell 1.7.3 + en_US dictionary (new, shared, seq 237-239)

Operator-requested (2026-09-04), for jinx in Emacs (seq 182). Three steps rather than
one, and the order between them matters.

enchant is a dispatch layer with no spelling engine of its own -- every provider it ships
(aspell, hunspell, nuspell, hspell, voikko) is optional and auto-detected at configure
time. Built before any provider exists it configures clean, installs clean, jinx compiles
clean, and every word comes back misspelled. So the recipe passes `--with-hunspell`
explicitly: a future re-seq that puts enchant first now fails at configure time instead of
silently. That is the same trap PRACTICES.md already records from pipewire quietly losing
ALSA to an `auto` meson feature.

The dictionary is its own numbered step for the same reason -- hunspell is an engine with
no words in it, and at the Emacs end a missing dictionary is indistinguishable from a
broken enchant. `/usr/share/hunspell` is not folklore: `s_buildDictionaryDirs()` in
`providers/enchant_hunspell.cpp` walks `g_get_system_data_dirs()` (this system's
`/usr/local/share:/usr/share`) and appends the provider name, and only accepts a
dictionary when the `.dic` and its matching `.aff` are both present. Read out of the
source, not assumed.

hunspell rather than nuspell or aspell: it is the format distributions actually ship
dictionaries in, it is plain autotools with no dependency past the toolchain, and BLFS
carries it. All three steps are shared recipes -- none names hardware.

Verified end to end rather than by "it installed":

- `/usr/lib/enchant-2/` contains exactly one provider, `enchant_hunspell.so`.
- `enchant-lsmod-2 -list-dicts` -> `en_US (hunspell)`. The recipe greps for that and
  fails the build if it is empty, which is the check that would have caught a
  provider-less enchant.
- `enchant-2 -d en_US -a` returns `*` for "correct" and
  `& speling 5 0: spieling, spelling, spewing, peeling, splinting".
- jinx itself: `jinx-20260813.954` was already in `~/.emacs.d/elpa` with its module
  unbuilt. Emacs was checked for dynamic-module support before any of this
  (`/usr/include/emacs-module.h` present, `module-file-suffix` = ".so"), then jinx's own
  `jinx--load-module` was invoked in batch -- its code path, its compile flags, not a
  hand-written cc line. "jinx-mod.so compiled successfully"; `jinx--mod-dict "en_US"`
  returns a dictionary, "correct" passes, "speling" fails and suggests. This wrote
  `jinx-mod.so` into the operator's elpa directory, which is what jinx does on its own at
  first startup anyway; delete it to undo.

Provenance is not uniform across the three and the recipes say so individually. hunspell
1.7.3's sha256 matches Arch's PKGBUILD byte for byte. enchant 2.8.21 has no second
packager's hash to check against -- Arch builds it from a git tag clone plus two gnulib
submodules, so its b2sum is over a source tree, not a release tarball -- and upstream
publishes no signature, so the record is the release asset's own sha256. The SCOWL
dictionary is thinnest: no signature, and no cross-check found. It is a word list parsed
as data rather than code, which is why that was judged acceptable rather than blocking.

### Verify after the reboot

    grep microcode /proc/cpuinfo            # expect 0xf0, not 0xc6
    cat /sys/devices/system/cpu/vulnerabilities/old_microcode   # expect "Not affected"
    ls /sys/class/powercap/                 # expect intel-rapl*
    grep -l coretemp /sys/class/hwmon/*/name
    journalctl -b -u thermald               # expect no "No Zones present"
    dmesg | grep -i regulatory              # expect no ENOENT for regulatory.db
    lsmod | grep -E 'coretemp|rapl|powerclamp|tcc'

Fallback if the new kernel misbehaves: GRUB entry
`pre-thermald-sensors fallback (2026-09-04)` boots
`vmlinuz-6.18.10-lfs-13.0-systemd.preTHERMAL`, and `/lib/modules/6.18.10.preTHERMAL` is
the matching module tree -- restore it over `/lib/modules/6.18.10` per the note in
`grub.cfg` if a fallback misbehaves.

### Still owed, unchanged from the earlier entry

`extract-recipes.py --check` / `extract-blfs.py --check` and a proper `blfs-plan.json`
regeneration still need a checkout that has the books; native mode has none, so zero
drift remains unconfirmed. The eleven recipes with a chroot-era `/etc/resolv.conf`
rewrite still need a native-mode guard.

## 2026-09-04 (continued): full health audit, stale pre-deploy tree found and removed, mode pinned

Operator asked for a full check that everything was running well and a cleanup pass
before continuing -- prompted by suspecting a wrong-repo mixup in a prior session.

**`lfsmaint`'s own package database was stale**, last built 10:27 that morning against
manifests from before the enchant/hunspell/oath-toolkit/pass-otp/intel-microcode/
wireless-regdb chain above (11:00-12:30). Rebuilt; `verify` came back clean (13
unexplained-missing files across 4 packages, every one individually accounted for: a
book-documented dbus doc-directory rename, two pulseaudio autostart files wireplumber's
own recipe deliberately removes, one permission-restricted sudoers file, and the
systemd-networkd units this host does not use since it runs NetworkManager instead).
One real gap found and fixed: `wireplumber`'s manifest only ever recorded its binaries
and libs, missing all 69 files under `/usr/share/wireplumber/` (config + Lua scripts) --
refilled from the live install, diffed against the old manifest first to confirm nothing
was dropped.

**The chroot tree at `/mnt/crypt/.../lfs` was gone through, moved, then removed.**
Checking it for staleness surfaced why `verify`/`orphans` against it looked catastrophic
(~50 packages "missing") before the mistake was caught: it is the pre-deploy staging
tree, superseded the moment the 2026-09-03 deploy (`17c4112`) succeeded, and every real
package since has correctly gone to the live root instead. 305 tarballs in its
`sources/` (2.3G) weren't yet cached in this host's real `/sources` -- copied over,
verified by checksum, before deleting the rest (~5.3G of stale installed files). Added
`build.mode` to the host.toml schema (`bin/lfshost.py`, `bin/lfsbuild`) so laptop pins
`mode = "native"` explicitly rather than depending on `detect_mode()`'s
populated-tree-wins-over-is_lfs_system() heuristic, which is what let that stale tree
fool a whole prior session into never needing `--native` explicitly and then, once
noticed, cost this one real effort to work out why. `server` is untouched, still
auto-detects as before.

**A second, independent clone of this whole repo was found at
`/mnt/crypt/john/projects/agent-built-lfs`** -- almost certainly the actual "wrong repo"
from the operator's prior session. Its committed history (`17c4112` and earlier) is a
strict ancestor of this checkout's `main`; its uncommitted working-tree edits
(`BUILD-REPORT.md`, `blfs-overrides.json`, `kernel-config.sh`, `packages.py`,
`state/completed`, `state/timings.tsv`, and a few unmodified files) checked out
byte-identical to what is already committed here, or a strict subset of it -- nothing
unique survived only there. Left for the operator to remove directly, along with the
1.6G `laptop-lfs-13.0-systemd.tar.zst` deploy archive next to it (the same deploy that
tarball was for already landed and booted).

`hosts/laptop/CLAUDE.md`'s "Not built yet"/"`packages.py` is still `BASE` alone" opening
(stale since the very first native package went in) and `host.toml`'s stale "Not built
yet" header were both corrected in the same pass, along with `BOOTSTRAP.md` (a status
note marking its chroot/archive/deploy steps historical -- they succeeded and are done,
not a live procedure -- while step 6, native, is where things actually stand) and
`packages.py`'s own header docstring. Committed as `5211a83` and pushed.

### hyprshot, to screenshot an unresolved terminal-rendering glitch (seq 240-245)

Operator-requested. Not in BLFS, same Hyprland-ecosystem sourcing policy as wofi/
Hyprland itself: Arch's own PKGBUILDs as the version/checksum reference where the book
has nothing. `recipes/blfs-jq.sh` already existed, shared, from `server`'s own seq 198
("needed by hyprshot" -- hyprshot itself was never actually reached there) -- built
there against jq's bundled vendored oniguruma, since no system copy existed on that
host. Revised rather than left alone: checked jq's own `configure.ac` before assuming a
real system library could replace the bundled one across both hosts, confirmed
`--with-oniguruma` defaults to probing the system copy and only falls back to the
vendored one (with a notice, never a hard failure) when it is absent -- so the same,
now-revised recipe still works unmodified on `server`, whether or not it ever gets its
own `oniguruma` step. Five real steps in dependency order -- `oniguruma` (240) before
`jq` (241) so jq links the real system library instead of silently bundling a private
copy (checked live via `ldd /usr/bin/jq`, not assumed); `grim` (242), `slurp` (243), `wl-clipboard`
(244) independently of each other and of jq; `hyprshot` (245) last, since it is a plain
script that only needs the other four (plus already-built `hyprctl` and `libnotify`) at
runtime, not build time. `oniguruma`/`slurp`/`wl-clipboard` sha256 match Arch's own
PKGBUILDs byte for byte; `grim` and `jq` are both git-tag sourced in Arch's own
PKGBUILD too, so there is no comparable packager hash for either -- recorded as this
session's own sha256 of the upstream release/tag archive, same class of gap enchant's
provenance note already carries. `hyprpicker` (README's one optional dep, for
`--freeze`) was not built: the script itself gates every call behind `command -v
hyprpicker` and degrades to a normal capture without it, and nothing else in this
project's plan wants it for its own sake -- add it later, as its own step, if `--freeze`
turns out to be wanted. All five shared recipes; none names hardware. Built clean,
253/258, `lfsmaint`'s database rebuilt and reverified clean afterward.

### GUI pinentry (real fix), bash-completion (seq 246-248)

Operator asked for a GUI pinentry and noticed `pass`/`pass-otp` tab-completion never
worked on this build. `book/blfs-13.0/` had been cleaned off this checkout at some
point (gitignored, upstream content) -- refetched from
`linuxfromscratch.org/blfs/downloads/13.0-systemd/blfs-book-13.0-systemd-html.tar.xz`
per `README.md`'s own instructions before anything else here could proceed.

First attempt at pinentry was a dead end, caught before it did anything useful: added
a host override forcing `--enable-pinentry-gtk2`, on the theory that GTK3 (already
present, seq 134, built before pinentry's seq 219) would satisfy it. Wrong -- the
build log (`hosts/laptop/logs/blfs-pinentry.log`) showed `checking for gtk+-2.0 >=
2.12.0... no`: pinentry's "gtk2" frontend is hardcoded to the real, obsolete GTK+2
pkg-config module regardless of name, not GTK3/4, and this project has never built
GTK+2. Override reverted rather than left in place doing nothing.

Real fix: the book's own `--enable-pinentry-gnome3` defaults to yes/auto and just
needs Gcr + libsecret present (`pinentry.html`: "uses Gcr-4.4.0.1 (or Gcr-3.41.2)").
Both are real BLFS pages, both lightweight here since their Required/Recommended
lists -- GLib, libgcrypt, p11-kit, GnuPG, GTK-4.20.3 -- were already built for other
reasons (BASE, seq 220, seq 206/pavucontrol). `libsecret` (seq 247) hit two real
`vapigen`-not-found meson failures (`-D vapi=false`, then `-D manpage=false` once
`xsltproc` was missing too) -- both optional per the book's own Recommended/Optional
lists, same class of doc/tool trap as the GTK4 chain. `gcr4` (seq 248) hit the same
`vapigen` gap, same fix. Both overrides recorded shared (`recipes/blfs-overrides.json`),
true of any host without Vala/libxslt, not laptop-specific. `pinentry` (seq 219)
re-run with the plain book default afterward -- no override needed once the real
dependency was there -- and now installs `pinentry-gnome3`, confirmed via the
build's own config summary (`GNOME 3 Pinentry .: yes`) and a live Assuan handshake
(`pinentry-gnome3 <<< BYE` answered `OK Pleased to meet you`). `/usr/bin/pinentry`
now symlinks there; GnuPG has no hardcoded `pinentry-program`, so this took effect
with no config change.

`bash-completion` (seq 246, hand-authored -- checked the book directly first, grepped
every page for the string: no dedicated framework page exists in BLFS 13.0, only
individual packages' own optional install hooks) is why `pass`/`pass-otp` never
autocompleted: both already install their completions correctly (confirmed in their
own manifests, `/usr/share/bash-completion/completions/pass` and
`/etc/bash_completion.d/pass-otp`) but nothing on this system ever sourced them.
Installed from upstream's 2.18.0 release tarball (github.com/scop/bash-completion --
no published checksum file, recorded as this session's own sha256, same gap already
noted for grim/enchant). Appended a source line for its `/etc/profile.d/bash_completion.sh`
into `/etc/bashrc` from the recipe itself (append, not an edit to the generated
`blfs-shell-startup-files.sh`) -- this project's `/etc/profile.d` is only sourced for
login shells, and ordinary interactive terminals need the fallback upstream's own
README documents for exactly this case. Confirmed live: `pass <TAB>` now loads and
binds `_pass` via bash-completion's on-demand loader.

Same `bash-completion` step added to `server`'s `packages.py` (seq 253, same shared
recipe) since the missing-sourcing gap is identical there, but not built from this
session -- `server` is a separate physical host. Plan regenerated
(`hosts/server/state/blfs-plan.json`) and verified zero-drift; the actual build is
for a session running there.

Built clean, 256/261 (was 253/258 before this; qt6 is the one open step, unrelated,
untouched this session). `lfsmaint`'s database rebuilt and reverified clean -- the
only "unexplained missing" entries are pre-existing (dbus/pulseaudio/sudo/systemd),
not touched by this work.

### GUI pinentry, part 2: it built but still showed curses (seq 249-250)

Operator report: still getting the CLI prompt after the above. Two real, separate
bugs, neither in the packages just built.

**Bug 1 -- a stray `gpg-agent`.** Two `gpg-agent` daemons were running for this user
(`~/.gnupg-auto` and `~/.gnupg`, the latter is the real default homedir `pass`/`gpg`
resolve to with no `GNUPGHOME` set). `/proc/<pid>/environ` on the `~/.gnupg` one
showed `WAYLAND_DISPLAY` present but `DBUS_SESSION_BUS_ADDRESS` completely absent --
it had been started (14:03:55, mid-session) from a shell that itself lacks that
variable, almost certainly this session's own tool shell, not a real terminal inside
Hyprland. `pinentry-gnome3` checks `$DBUS_SESSION_BUS_ADDRESS` itself and silently
falls back to curses when it's unset; a child inherits its parent's environment, so
every pinentry that agent ever spawned would carry the same gap until restarted.
Fix: `GNUPGHOME=/home/john/.gnupg gpgconf --kill gpg-agent`, then let it respawn
attached to a proper environment -- verified via `/proc/<new pid>/environ` before
declaring it fixed. `~/.gnupg-auto`'s agent (the automation/`pass-auto` one referenced
in `hyprland.lua`'s autostart block) was left alone -- out of scope, and headless by
design.

**Bug 2 -- Gcr had no System Prompter.** Even with the environment fixed, pinentry
printed `No Gcr System Prompter available, falling back to curses`. `gcr4` (built in
part 1) only ships that API's *headers* (checked: nothing under `/usr/libexec` names
a prompter). The real `org.gnome.keyring.SystemPrompter` D-Bus service is `gcr-3`'s
own `gcr-prompter` binary, activated via a `.service` file that `gnome-keyring`
installs -- and `gnome-keyring.html`'s own Required list wants Gcr-3.41.2
specifically, the pre-GTK4 line (book page `gnome/gcr.html`, package name `gcr` here
to distinguish from `gcr4`), not what was already built. Two more real BLFS pages,
seq 249-250, laptop only (not added to `server`, nobody asked for one there):

- `gcr` (249): book default fails on `vapigen` like `gcr4`/`libsecret` did, but this
  older release has no separate `vapi` meson option at all (checked
  `meson_options.txt` directly) -- GIR and VAPI generation are both gated by the
  single `introspection` option (`gck/meson.build`), so that's what had to go, not a
  vapi-specific flag. GObject Introspection is Recommended for GLib, not something
  this project's actual use of `gcr-3` (a D-Bus prompter binary, not a GNOME desktop)
  needs at runtime.
- `gnome-keyring` (250): book default fails on `libpam` (`-D pam=false` -- Linux-PAM
  is Recommended, not built anywhere in this project, same standing gap as every
  other PAM-optional package here), then on `xsltproc` for man pages (`-D
  manpage=false` -- libxslt gap already hit on `libsecret`). `ssh-agent` needed no
  override: this release's meson option already defaults to false.

Installing `gnome-keyring` is what actually places `/usr/share/dbus-1/services/
org.gnome.keyring.SystemPrompter.service` (`Exec=/usr/libexec/gcr-prompter`, from the
just-built `gcr`) -- confirmed live: `pinentry-gnome3 <<< BYE` now returns `OK
Pleased to meet you` with **no** fallback line, and the prompter needed no daemon
running ahead of time (D-Bus activates it on demand). `gnome-keyring-daemon`'s other
two components (`secrets`, the Secret Service API arbitrary apps use; `pkcs11`) are a
separate, broader concern from the prompter itself -- operator asked for these to
autostart too, so an `hl.exec_cmd("gnome-keyring-daemon --start
--components=pkcs11,secrets")` line went into `hyprland.lua`'s existing `hyprland.start`
autostart block, matching the `--components` this build's own
`/usr/lib/systemd/user/gnome-keyring-daemon.service` already specifies. **That file is
in `~/Config`, the operator's own separate dotfiles repo -- not part of
`agent-built-lfs`, checked clean (`git status`) before editing, and outside this
project's override/seq machinery entirely.** Takes effect on the next Hyprland
restart; started manually this session too (`gnome-keyring-daemon --start
--components=pkcs11,secrets`, confirmed running) so the fix is live without one.

### mu4e (seq 251-256)

Operator-requested. Scanned `~/Config/common/emacs.d/` first rather than assuming a
blank slate: `email.el` already hardcodes `/usr/share/emacs/site-lisp/mu4e/` and
`mu4e-get-mail-command "mbsync -a"`; `~/Config/common/isync/mbsyncrc` already
configures all 5 accounts (gmail-cobus, infocus, and three fatcow addresses) with
`PassCmd` calling back into `emacsclient` + a `my/lookup-password` helper built on
`auth-source-search`; `~/.authinfo.gpg` and `~/email/` (real maildirs, 14526 messages
across all 5 accounts) already existed from a prior system. None of that needed
touching -- only the packages backing it were missing.

Real deps checked directly against each project's own build files before writing
anything, same discipline as the pinentry chain: `gpgme` (postlfs/gpgme.html,
Required libassuan already built) before `gmime3` (general/gmime3.html, Required
GLib/libgpg-error already built, gpgme Optional and auto-detected via pkg-config --
confirmed via `ldd libgmime-3.0.so` afterward) before `xapian`
(general/xapian.html, no hard deps, 3.3 min build -- the slow one). `mu` 1.14.3 is
hand-authored (no BLFS page; mu4e's elisp has shipped inside mu's own tree since mu
1.4, no separate tarball exists) -- checked meson.build directly: needs
glib/gio>=2.80, gmime-3.0>=3.2.13, xapian-core>=1.4.22 (all satisfied), fmt/CLI11
optional with a vendored fallback (CLI11 happens to already be present from the
quickshell/DMS chain), guile/scm default to meson feature 'auto' and skip quietly.
Confirmed `lispdir`'s default (`datadir/emacs/site-lisp/mu4e`) resolves to exactly
what `email.el` hardcodes, with no override needed. `isync` 1.5.1 (mbsync) is also
hand-authored (no BLFS page) -- plain autotools, `--with-ssl`/`--with-sasl` both
auto-detect and this project's mbsyncrc uses plain IMAPS auth, so OpenSSL (already
built) was enough. Official checksums existed for both hand packages this time (mu
publishes a real sha256sum file; isync's md5 came from SourceForge's own file API) --
better provenance than most hand-authored recipes here.

`xdg-utils` (xsoft/xdg-utils.html) was a separate mid-task request, unrelated to
mu4e. Two real failures, not one: book's plain `make` builds `html man scripts`
unconditionally via xmlto (Required per the page's own dependency list, not built --
same standing xmlto/docbook/libxslt gap as everywhere else in this project, and a
3-package cascade nobody asked for). First fix (`make -C scripts scripts` alone)
still failed -- turns out the *scripts* themselves depend on xmlto too:
`generate-help-script.awk` (checked directly) splices each script's own `--help`
text from a `.txt` file generated by `xmlto txt`. Fixed by writing a one-line
placeholder `.txt` per script (pointing at the real docs) before the build, dated
after its `desc/*.xml` source so make's timestamp check never triggers xmlto --
scripts work identically, only `--help` text is generic. Shared override (any host
without xmlto hits this the same way).

Real, unrelated bug caught during verification, not a new package: `mbsync --list
--all` failed outright (`CertificateFile '/etc/ssl/certs/ca-certificates.crt': No
such file or directory`, exit 1) -- `~/Config/common/isync/mbsyncrc` was written
against a Debian/Arch-style system where `ca-certificates` installs a bundle at that
exact path; this project's own CA store (`make-ca`, BASE seq 4) uses the LFS/RedHat
convention instead, `/etc/pki/tls/certs/ca-bundle.crt` -- confirmed that file
actually exists and is populated (185 KB, from the original CA store build) before
touching anything. Fixed by pointing `mbsyncrc`'s 5 `CertificateFile` lines at the
real path rather than inventing a compatibility symlink -- `~/Config` is the
operator's own separate dotfiles repo, checked `git status` first (some unrelated
DMS/cursor files were already modified live by the running shell, left untouched).
`mbsync --version`/`--list --all` both confirmed clean afterward.

Verified end-to-end: `mu4e.el` loads cleanly under `emacs --batch`
(`mu4e-mu-version` reads 1.14.3), `mu init --maildir=~/email` + `mu index` indexed
all 14526 existing messages with zero errors, `mu find ""` confirms all 14526 are
searchable. Nothing left for the operator except actually opening Emacs and hitting
`C-c m` -- `mu4e-alert`'s desktop notifications still need a running notification
daemon (noted in the previous entry: DankMaterialShell isn't up in this session),
but that's unrelated to mu4e itself working.

## 2026-09-04: imv + Slack (seq 257-258)

Both operator-requested, both hand-authored (neither has a BLFS page -- imv is small
enough BLFS never carried it, Slack is proprietary and never will be).

`imv` 4.3.0 (github.com/eXeC64/imv, MIT, latest tag): every required dep and every
enabled image backend (libtiff/libpng/libjpeg-turbo/librsvg, all `feature: auto` in
its own meson_options.txt) was already built on this host; freeimage/libnsgif/libheif
stayed disabled rather than adding three packages for backends nothing needs. Built
`-Dwindows=wayland` (not the meson default `all`) because this host has no libGLU,
which the x11 backend requires unconditionally, and there is no real X11 session to
use it from. First build attempt failed at link time: `ubrk_close_78` undefined --
imv's own console.c calls ICU's break-iterator API (libicuuc) but only declares
`dependency('icu-io')`, and this host's `icu-io.pc` lists `icu-i18n` under
`Requires.private` (correctly excluded from a plain `--libs`, per the pkg-config
spec), so nothing on the link line ever pulled libicuuc in. Fixed with
`-Dc_link_args=-licuuc` rather than patching imv's meson.build -- the real defect is
this host's ICU packaging shape, not imv. Second attempt built and installed clean
(7 files). `imv -v` confirms `4.3.0`; all runtime libs resolve.

Operator caught what the build alone missed: `imv` opened a real screenshot and
crashed/hung outright (`interface 'xdg_toplevel' has no event 3`, then, after the
first fix, two further crashes in turn -- `listener function for opcode 4 of
wl_output is NULL`, then opcode 2 of `wl_surface`). `imv -v`/`--version` never
touches the Wayland path at all, so the earlier "all runtime libs resolve" check
never would have caught this -- a real gap in what "verified" meant for a GUI
package, worth remembering for the next one. All three were the same underlying
upstream bug, not three separate ones: `wl_window.c`'s `on_global()` binds every
Wayland global (compositor, xdg_wm_base, seat, output) at whatever version the
compositor advertises, uncapped against what imv's own hand-written listener
structs actually implement, and `src/xdg-shell-protocol.c`/
`-client-protocol.h` are pre-generated files checked into imv's release tarball
("Generated by wayland-scanner 1.17.0", an ancient xdg-shell v2 snapshot) rather
than produced from the build host's own wayland-protocols. Hyprland is built
against a modern, fully-featured protocol stack, so it readily offers everything
those stale/uncapped bindings request, and imv's client code has no slot for most
of it. No upstream fix exists (checked eXeC64/imv's issues before writing one).
Fixed in the recipe, not by patching imv upstream: regenerated both protocol files
from this host's real wayland-protocols (version 7) with the system's own
wayland-scanner, then `sed`-capped four `wl_registry_bind()` calls to the highest
version each corresponding listener (or, for compositor/xdg_wm_base/seat, the
child object it creates) actually covers -- `wl_compositor` at 4, `xdg_wm_base` at
3, `wl_seat` at 5, `wl_output` at 3, each verified by reading every listener
struct in the file, not guessed. Verified end-to-end after: the same screenshot
opened under the live Hyprland session with no crash, `hyprctl clients` showing a
real mapped/visible window titled with imv's own post-decode metadata
(`[674x370] [96%]`) -- the actual pixel dimensions, obtainable only after a
successful decode, not just a launch.

Slack Desktop 4.52.155: ships Linux builds only as `.deb`/`.rpm`/Snap (checked
slack.com/downloads/linux directly -- no tarball option), so this unpacks the
official `.deb` (downloads.slack-edge.com/desktop-releases/linux/x64/4.52.155/, the
real URL its own download-instructions redirect resolves to) with `ar`+`tar`, tools
already in the closure, rather than bringing in dpkg. `ldd` against the real binary
before writing anything found everything else already satisfied by this host's
existing GTK3/Wayland/XWayland/pipewire/at-spi2 stack except `libcups.so.2` -- a
genuine direct ELF `NEEDED` (Chromium's print backend links it, doesn't dlopen it),
and this host has never built CUPS. Operator's call: stub it rather than build the
real `cups.html` chain for one proprietary app's print dialog -- Slack will always
report zero printers, nothing else. First stub pass grepped `readelf --dyn-syms` for
only `cups*`-prefixed symbols (26 of them) and loaded fine but crashed on first real
launch (`undefined symbol: ppdOpenFd` -- CUPS's surface is bigger than its own name
prefix: `http*`, `ipp*`, and `ppd*` symbols too). Re-derived the full 68-symbol UND
list and rewrote the stub against that; each call returns 0/NULL/""(the same shape
real CUPS returns with no server or printers present) except the `ipp_t`/
`ipp_attribute_t` constructor calls, which real callers never NULL-check, so those
return a shared dummy non-NULL pointer instead. `chrome-sandbox` installed
setuid-root (matches every other distro's packaging of this same upstream binary) so
Chromium's SUID sandbox actually engages. The .deb's own `etc/cron.daily/slack`
(apt-based auto-updater) was not installed -- no apt on this system for it to call.

Verified end-to-end, not just linked: launched for real under the live Hyprland
session (`WAYLAND_DISPLAY=wayland-1`) -- `hyprctl clients` confirmed a mapped,
visible `slack` window ("Sign in | Slack"), main window shown, network status
online, no crash. Closed afterward; this was an install verification, not a login.
