# Hyprland installation plan

Goal: a working Hyprland (Wayland compositor) session on this box, with NVIDIA
hardware acceleration. Neither Wayland nor Hyprland exist in the BLFS 13.0 book.
Sourcing policy per standing instruction: BLFS recipe where the book has one,
otherwise Arch's official packaging (checked AUR first each time — as of this
plan every package below turned out to live in Arch's official `extra` repo,
none actually needed AUR).

Confirmed via live queries against archlinux.org and the local BLFS book mirror
on 2026-08-25, not from memory.

## Progress checkpoint (2026-08-26)

**Tiers 1-4 built and verified working**: cmake through the full GPU/GL stack
(SPIRV-Headers/Tools, Glslang, Vulkan-Headers/Loader, libdrm, Mesa, libepoxy,
libglvnd) — `libGL.so`/`libEGL.so` confirmed present from both Mesa and
libglvnd's vendor-neutral dispatch layer. 246 packages tracked total (135 BLFS).

Real dependency gaps the original plan missed, found only by letting the build
fail and reading the actual error (not caught by scanning book/PKGBUILD
dependency lists ahead of time): `xtrans`, `libX11`/`libXext` (whole legacy
X11 lib family wasn't in this BLFS mirror at all), `libXrender` →
`libXrandr` → Vulkan-Loader's X11 WSI needs both in that order,
`libxshmfence` and `libXxf86vm` for Mesa's X11 platform support. Each fixed
the same way: read the real configure/meson error, pull the matching Arch
PKGBUILD, add a hand-authored recipe using this project's `$XORG_CONFIG`
convention, resume.

**Mesa driver scope, finalized**: `gallium-drivers=nouveau` only (no
llvmpipe — needs LLVM, decided against building it). `vulkan-drivers=`
**empty — no Vulkan driver at all.** Discovered mid-build: `vulkan-drivers=swrast`
is lavapipe internally, and meson flatly refuses `-D llvm=disabled` together
with it ("Lavapipe Vulkan driver requires LLVM"). Combined with NVK (real
nouveau Vulkan) already ruled out for Kepler-support reasons, the honest
outcome is: **this system has OpenGL acceleration via nouveau, and no Vulkan
support at all.** Reported to the operator as a direct, known consequence of
the earlier LLVM-avoidance call, not a new fork.

**Tier 6 complete**: freetype2 rebuilt against harfbuzz, the Rust toolchain
(own bundled LLVM), libssh2, cargo-c, cbindgen, cairo, fribidi, pango,
shared-mime-info, gdk-pixbuf, librsvg. Two dependency gaps missed by the
original plan, found the same way as Tier 1-4's: `fribidi` (pango's own
Required dep, never added), and `gdk-pixbuf`/`shared-mime-info` (librsvg
lists gdk-pixbuf only as Recommended, but its `rsvg-pixbuf.h` header hard
`#include`s `gdk-pixbuf/gdk-pixbuf.h` — build fails outright without it;
skipped gdk-pixbuf's other Recommended dep, `glycin`, a circular
Rust-image-loader rebuild loop out of scope for the one-level policy).
Also hit a recurring pattern across several Tier 6 packages: meson/autotools
blocks for optional docs (`man-pages`/`documentation` needing `rst2man` or
Gi-DocGen, `doxygen` API docs, `texlive` PDF docs) left enabled by the book
by default even though none of those doc tools are installed — dropped each
one as found (pango, gdk-pixbuf's `man` meson option, json-c, popt,
libassuan, gnupg).

**Two out-of-scope additions, also complete** (operator request,
2026-08-26, not part of the Hyprland stack itself): `cryptsetup` (via
`libaio` → `json-c` → `popt` → `LVM2` → `cryptsetup`; kernel gate —
`CONFIG_DM_CRYPT`, `CONFIG_CRYPTO_XTS`, `CONFIG_CRYPTO_USER_API_SKCIPHER`
are still not set on `6.18.10-nftables`, so the tool is installed and
verified (`cryptsetup 2.8.4`) but can't open/create encrypted volumes until
a follow-up kernel rebuild, batched with the still-pending
`CONFIG_DRM_NOUVEAU` addition below) and `pass` (full GnuPG chain:
`libgpg-error`, `libgcrypt`, `libassuan`, `libksba`, `npth`, `openldap`
client-only build, `pinentry --enable-pinentry-tty`, `gnupg 2.5.17`, `tree`
— `pass version` confirmed working). Package db rebuilt: 249 packages,
67610 files tracked.

**Tier 8 complete** (input/session): libevdev, mtdev, libgudev, libwacom,
lua5.4, libinput, seatd. Two real defects found and fixed: `lua5.4`'s
Makefile defaults `INSTALL_TOP` to `/usr/local`, so the library/headers/
binaries landed there while its `.pc` file (hardcoded `prefix=/usr`)
pointed pkg-config at `/usr` -- a mismatch that would have broken
libinput's dependency probe; added `INSTALL_TOP=/usr` to the install line.
`libevdev` and `libinput` both default their `tests` option to enabled and
hard-require the Check framework (libevdev) or default `debug-gui` to
needing GTK3/4 not yet built (libinput) -- disabled both.

**Tier 9 complete** (XWayland): attrs (Python, pip3, needed hatchling via
normal pip build-isolation rather than pyyaml/mako's `--no-build-isolation`
pattern -- discovered when attrs' hatchling backend wasn't present), dbus,
libei, xorg-font-util, then two dependencies xwayland's real meson.build
hard-requires but the book's documented dependency list never mentions at
all: `libxkbfile` and `libfontenc`/`libXfont2` (found only by letting the
xwayland configure fail on `Dependency "xkbfile" not found`). `Xwayland
-version` confirmed working (24.1.9).

Next: Tier 10, the Hyprland ecosystem proper, researched just-in-time.

253 packages tracked, 67920 files, as of this checkpoint.

## Progress checkpoint (2026-08-26, later): Hyprland itself is built and working

**Tier 10 complete.** All 26 planned packages (libjpeg-turbo, muparser,
libXfixes, libXcomposite, libXcursor, the xcb-util-image/keysyms/renderutil/
wm/errors family, libzip, pugixml, re2, tomlplusplus, hyprwayland-scanner,
hyprutils, hyprlang, hyprcursor, hyprgraphics, hyprwire, hyprland-protocols,
glaze, aquamarine, hyprtoolkit, hyprland-guiutils, and Hyprland itself)
built and installed. `Hyprland --help` (with `XDG_RUNTIME_DIR` set) prints
its usage cleanly and `ldd` shows no missing shared libraries -- the
compositor binary is sound. Real interactive verification (an actual
logged-in Wayland session) still needs to happen at the physical console,
outside what this SSH-driven build process can exercise.

Real defects found only by letting each real build fail, in order hit:
- `libjpeg-turbo` and `muparser`: both claimed "already built" in earlier
  rationale comments for hyprgraphics/hyprland but never actually added to
  the recipe list -- caught by checking for their manifests before staging
  Tier 10, same class of oversight as fribidi in Tier 6.
- `hyprtoolkit` hard-requires `iniparser` via pkg-config, undocumented in
  every Hyprland-ecosystem PKGBUILD (a transitive probe, not a declared
  packaging dependency).
- Hyprland's own CMakeLists hard-requires `wayland-protocols>=1.49` (this
  BLFS book mirror only has 1.47) -- which itself requires
  `wayland-scanner>=1.25.0`, forcing wayland up from the book's 1.24.0 to
  1.26.0 too. Neither bump needed recipe changes -- both are generic,
  version-independent meson builds.
- Hyprland also hard-requires Lua **5.5** specifically (`lua55`/`lua5.5`/
  `lua-5.5`/`lua>=5.5,<5.6`), wholly undocumented and distinct from
  libinput's Lua 5.4 dependency (Tier 8) -- the two major versions are not
  ABI-compatible and now coexist under separate pkg-config names. Building
  it exposed two more real snags: the `paths.patch` used for 5.4 fails to
  apply against 5.5.1's reformatted `luaconf.h` (skipped -- moot anyway for
  a library-only build nothing invokes as a CLI), and `TO_BIN=""` to avoid
  clobbering lua5.4's `/usr/bin/lua` fails outright (the Makefile's install
  rule has no guard for an empty file list) -- accepted the overwrite
  instead, since nothing on this system runs the Lua CLI regardless of
  which version's binary ends up on `PATH`.
- **A genuine GCC 15.2 / libstdc++ gap**, not a packaging issue: Hyprland's
  own source uses `std::ranges::starts_with`, a C++23 range algorithm this
  GCC's libstdc++ does not implement even under `-std=gnu++2c` (confirmed
  by hand-compiling a minimal reproduction; `ranges::contains` and
  `ranges::fold_left` *do* work, so this is narrow, not a broad C++23 gap).
  Only one call site in the whole tree used it
  (`src/helpers/MiscFunctions.cpp`, in `truthy()`); patched it to
  materialize a lowercased `std::string` and use the C++20 member function
  `std::string::starts_with` instead, which does work.

Package db: 257 packages, 68426 files, as of this checkpoint.

Remaining scope: Tiers 11-15 (GTK3/PulseAudio prerequisites, media codecs,
ffmpeg, mpv, Firefox), researched just-in-time per the standing policy.

## Progress checkpoint (2026-08-26, later still): Tier 11 complete

GTK3/PulseAudio prerequisite chain, all real BLFS book pages: libogg,
FLAC, Opus, libvorbis, libsndfile, alsa-lib (+ its alsa-ucm-conf
"Recommended file" secondary download), speex (+ its required speexdsp
second tarball), gsettings-desktop-schemas, at-spi2-core, GTK3, PulseAudio.
`pulseaudio --version` (17.0) and `gtk-launch --version` (3.24.51) both
confirmed working.

Two more undocumented hard dependencies found via real failures, both
X11-legacy libraries the book's generic "Xorg Libraries" mention doesn't
break down: at-spi2-core needed `libXtst` (XTEST/RECORD, for accessibility
input injection), which itself needed `libXi`; PulseAudio separately needed
`libICE` and `libSM` (Inter-Client Exchange / Session Management). Also
fixed two doc-tool traps matching the session's recurring pattern: alsa-lib's
optional Doxygen API-doc build, and GTK3's book-hardcoded `-D man=true`
(needs docbook-xsl-nons/libxslt, not installed) -- set to false.

Package db: 272 packages, 69839 files, as of this checkpoint.

## Progress checkpoint (2026-08-26, after a power/internet outage): Tier 12 complete

Tier 12 (nasm through sdl2-compat, 14 packages) ran to completion on target
just minutes before the host lost power and internet. One real gap found
and fixed the same way as every other tier: SDL3 hard-requires
`libXScrnSaver`, undocumented anywhere upstream -- hand-authored recipe
added, resumed, finished clean. Full outage/recovery detail (manifest
reconstruction after `/tmp` was wiped by the reboot, a stale-timestamp bug
found and fixed in `blfs-screen`'s manifest, and a stale plan.json on
target that was silently dropping `libxscrnsaver` from the package db) is
in `BUILD-REPORT.md`'s own outage section rather than duplicated here.

Package db: 288 packages, 70034 files, as of this checkpoint.

Next: Tier 13 (libplacebo, ffmpeg), Tier 14 (mpv), real LLVM+clang, Tier 15
(Firefox) -- resuming now.

## The NVIDIA situation — read this first

The card is PCI `10de:1184`, confirmed against the pci-ids database as
**GK104 [GeForce GTX 770]** — Kepler architecture, 2013.

This matters a lot:

- NVIDIA's current driver branches (the ones in Arch's official `nvidia` /
  `nvidia-open` packages) **dropped Kepler support years ago**. `nvidia-open`
  never supported Kepler at all — it starts at Turing.
- The only proprietary driver that runs on this card is the **legacy 470.xx
  branch**, frozen at **470.256.02**. Confirmed via AUR: `nvidia-470xx-utils`
  and friends exist there specifically because Arch's official repo can't carry
  it (one driver version per repo, and official tracks current). Last updated
  June 2024 — it is not receiving further updates, ever.
- That branch predates explicit-sync support (the protocol modern
  wlroots/Hyprland-family compositors increasingly assume for tear-free NVIDIA
  operation). Expect real rough edges — possible tearing, flickering, or
  compositor-side workarounds needed — not the smooth experience NVIDIA users
  on Turing+ get with the current driver. This is a hardware ceiling, not
  something more careful packaging fixes.
- BLFS does not package NVIDIA's driver at all (license terms, not a gap in the
  book), and neither does Arch's community packaging beyond the AUR PKGBUILD
  that just wraps NVIDIA's `.run` installer. There's no "recipe" here in the
  BLFS sense — it's: fetch NVIDIA's archived 470.256.02 `.run` installer,
  build its kernel module against this system's exact kernel headers, install.
  That coupling means **the NVIDIA kernel module has to be rebuilt every time
  the kernel changes** — including the netfilter rebuild happening right now.
  No DKMS on this system, so that rebuild is a manual step each time, not
  automatic.
- Fallback available at every stage: **nouveau** (open-source, in-kernel,
  covers Kepler fully) gives working GBM/DRM-KMS accel through Mesa with zero
  extra packaging — just a kernel config flag. Weaker 3D/compute performance
  than the proprietary driver, no CUDA, but modern, well-integrated Wayland
  behavior with no driver-version coupling to fight.

**Recommendation:** build Mesa with nouveau support regardless (it's in the
Mesa build either way, effectively free), get Hyprland running and verified on
nouveau first, *then* layer the proprietary 470.256.02 driver on top as a
swap-in once the base stack is proven — rather than debugging Hyprland and an
EOL driver branch at the same time. This plan builds the stack so either GPU
backend works; the 470.256.02 install itself is its own section below, done
last, opt-in.

## Kernel considerations

Two separate concerns:

1. **nouveau**: needs `CONFIG_DRM_NOUVEAU`, which isn't in the current kernel
   config (confirmed during the baseline hardware audit — this GPU currently
   has no driver bound at all). Add it to `kernel-config.sh` as `=m` alongside
   the netfilter changes already going into this rebuild, or in a follow-up
   rebuild — cheap to fold into the kernel work already in flight.
2. **Proprietary driver**: doesn't need kernel config changes, but needs
   matching kernel headers/build tree present for whichever kernel is running
   when its module gets built (same requirement DKMS normally automates).

## Build order

Tiers are dependency order; within a tier, order doesn't matter. `[BLFS]` =
book has a real page, used as-is or with the same kind of override this
project already applies elsewhere. `[Arch]` = no BLFS page, build from
upstream source using Arch's official `extra` PKGBUILD as the reference for
version/flags/deps (all confirmed in `extra`, zero from AUR for actual
packages — AUR only had the NVIDIA legacy driver wrapper).

**Tier 1 — build tooling**
- `cmake` `[BLFS general/cmake.html]` — meson/ninja already present from base LFS (ch08)

**Tier 2 — low-level libs**
- `pixman` `[BLFS]`, `libpng` `[BLFS]`, `libwebp` `[BLFS]`, `libjxl` `[BLFS]`,
  `freetype2` `[BLFS]`, `fontconfig` `[BLFS]`, `harfbuzz` `[BLFS]`,
  `abseil-cpp` `[BLFS]`, `nettle` `[BLFS]`, `libtirpc` `[BLFS]`,
  `libdisplay-info` `[BLFS]`
- `libjpeg-turbo` `[Arch]`, `re2` `[Arch, depends on abseil-cpp above]`,
  `pugixml` `[Arch]`, `libzip` `[Arch]`
- `libffi` — already present (Python pulled it in)

**Tier 3 — Wayland core**
- `wayland` `[BLFS]`, `wayland-protocols` `[BLFS]`, `libxkbcommon` `[BLFS]`

**Tier 4 — GPU/GL stack**
- `libdrm` `[BLFS]`, `mesa` `[BLFS]` (build with `gallium-drivers=nouveau`
  among others — this is where the kernel's `CONFIG_DRM_NOUVEAU` pairs up),
  `libepoxy` `[BLFS]`, `vulkan-loader` `[BLFS]`, `glslang` `[BLFS]`
- `libglvnd` `[Arch]` — vendor-neutral GL dispatch; this is the piece that
  lets Mesa's nouveau path and (later) NVIDIA's proprietary libGL coexist and
  be switched via `opengl-driver`/`__GLX_VENDOR_LIBRARY_NAME` without conflict

**Tier 5 — X11/XCB compatibility (for XWayland)**
- `libxcb` `[BLFS]`, `xcb-proto` `[BLFS]`, `xorgproto` `[BLFS]`,
  `libXau` `[BLFS]`, `libXdmcp` `[BLFS]`, `libxcvt` `[BLFS]`,
  `xcb-util` `[BLFS]`
- Not in this BLFS mirror at all, `[Arch]`: `libX11`, `libXext`, `libXrender`,
  `libXfixes`, `libXcomposite`, `libXcursor`, `xcb-util-image`,
  `xcb-util-keysyms`, `xcb-util-renderutil`, `xcb-util-wm`, `xcb-util-errors`,
  `libxkbfile`, `libxfont2`, `xtrans`

**Tier 6 — Rust toolchain**
Decided: yes, build it — Firefox needs it too (`cbindgen` is itself a Rust
program), so this is shared cost, not librsvg-only.
- `llvm` `[BLFS]` — built with `-D LLVM_LINK_LLVM_DYLIB=ON` per the book, so
  Rust links the system LLVM instead of building its own copy
- `libssh2` `[BLFS]` — Rust's other recommended dep
- `rust` `[BLFS general/rust.html]` — required: cmake (tier 1), curl (already
  present); recommended: libssh2 + llvm above
- `cbindgen` `[BLFS]` — a Rust program itself; required by Firefox (tier 15)

**Tier 7 — Cairo/Pango stack**
- `cairo` `[BLFS]`, `pango` `[BLFS]`
- `librsvg` `[BLFS]` — needs the Rust toolchain from tier 6. Used by
  `hyprcursor`/`hyprgraphics` (SVG cursor theme + image loading).

**Tier 8 — input & session management**
- `libwacom` `[BLFS]`, `mtdev` `[BLFS]`
- `libevdev` `[Arch]`, `lua5.4` `[Arch — BLFS only has LuaJIT, Arch's
  libinput wants Lua 5.4 specifically for its device-quirk scripts]`,
  `libinput` `[Arch]`
- `seatd` `[Arch]` — provides `libseat`, backed by this system's existing
  `systemd-logind` (already present, part of the systemd already built) rather
  than needing the standalone `seatd` daemon running

**Tier 9 — XWayland**
- `dbus` `[BLFS general/dbus.html]` — not yet built, needed by xorg-xwayland's
  build and by session/portal machinery generally
- `libei` `[BLFS, already has a page]`
- `libdecor` `[Arch]`, `xorg-font-util` `[Arch]`, `xorg-server-common` `[Arch]`
- `xorg-xwayland` `[BLFS x/xwayland.html]` — the outer package has a real BLFS
  page even though some of its own sub-deps above don't

**Tier 10 — Hyprland ecosystem (all confirmed in Arch's `extra`, none in BLFS)**
Build order matters here — this is a real dependency chain, not a flat list:
1. `hyprwayland-scanner` `[Arch]`
2. `hyprutils` `[Arch]` (needs pixman, already built)
3. `tomlplusplus` `[Arch]`
4. `hyprlang` `[Arch]` (needs hyprutils)
5. `hyprcursor` `[Arch]` (needs hyprlang, librsvg, libzip, cairo)
6. `hyprgraphics` `[Arch]` (needs hyprutils, cairo, pango, libjpeg-turbo, libpng, libwebp, libjxl, librsvg)
7. `hyprwire` `[Arch]` (needs hyprutils, libffi, pugixml)
8. `hyprland-protocols` `[Arch]` (meson-only, no deps)
9. `glaze` `[Arch]` (header-only-ish, cmake)
10. `aquamarine` `[Arch]` (needs hyprutils, hyprwayland-scanner, libdrm,
    libdisplay-info, libinput, libseat, mesa, pixman, wayland,
    wayland-protocols — this is the wlroots-successor rendering/backend layer)
11. `hyprtoolkit` `[Arch — not yet looked up in detail, pulled in by
    hyprland-guiutils below]`
12. `hyprland-guiutils` `[Arch]` (needs hyprlang, hyprtoolkit, hyprutils, libdrm, pixman)
13. `hyprland` `[Arch]` itself — needs everything above plus `lcms2` `[BLFS]`,
    `muparser` `[BLFS]`, `glib2` `[BLFS, tier 11]`, and the X11/XCB
    tier for XWayland integration

## Extended scope: Firefox, mpv, ffmpeg (added 2026-08-25)

All three have real BLFS pages. Their combined dependency closure overlaps
heavily with what Hyprland already needs (mesa, pixman, cairo, pango,
fontconfig, freetype2, harfbuzz, libwebp, libjxl, wayland — tiers 2-7 above),
plus `nodejs`, already built as part of the original BLFS baseline for Claude
Code — the new, genuinely additive pieces are below, still dependency-ordered.

**Tier 11 — GTK3 & desktop-audio prerequisites**
- `glib2` `[BLFS]` — needed by GTK3, Hyprland itself, and generally
- `gtk3` `[BLFS x/gtk3.html]` — pulls its own sizeable BLFS-covered tree
  (atk, gdk-pixbuf, at-spi2-core, etc.) — required by Firefox
- `libnotify` `[BLFS]`, `startup-notification` `[BLFS]`, `libarchive` `[BLFS]`
  — required by Firefox
- `libevent` `[BLFS]`, `icu` `[BLFS]`, `nss` `[BLFS]` — required/recommended
  by Firefox
- `pulseaudio` `[BLFS multimedia/pulseaudio.html]` — **required** by both
  Firefox and mpv; this is a real new subsystem addition (audio server), not
  a small dep, on a box that's been headless-server-only until now
- `alsa-lib` `[BLFS]` — required by mpv, recommended by ffmpeg
- `libva` `[BLFS]`, `sdl2-compat` `[BLFS multimedia/sdl2.html — the book
  files it under "sdl2.html" but the package itself is sdl2-compat]`,
  `uchardet` `[BLFS]` — recommended by mpv/ffmpeg

**Tier 12 — media codec libraries (all ffmpeg "Recommended")**
- `dav1d` `[BLFS]`, `libaom` `[BLFS]`, `libvpx` `[BLFS]`, `opus` `[BLFS]`,
  `x264` `[BLFS]`, `x265` `[BLFS]`, `svt-av1` `[BLFS]`, `lame` `[BLFS]`,
  `fdk-aac` `[BLFS]`, `libass` `[BLFS]`, `nasm` `[BLFS]` (build tool for
  several of the above, not a library)

**Tier 13 — FFmpeg**
- `libplacebo` `[BLFS]` — needed by both ffmpeg (optional, HDR tonemapping)
  and mpv (required)
- `ffmpeg` `[BLFS multimedia/ffmpeg.html]` — built against everything in
  tier 12 plus alsa-lib/libva/sdl2-compat from tier 11

**Tier 14 — mpv**
- `mpv` `[BLFS multimedia/mpv.html]` — required: alsa-lib, ffmpeg, libass,
  libplacebo, mesa, pulseaudio (all already built); recommended:
  libjpeg-turbo (tier 2), libva (tier 11), luajit (new — BLFS has it; distinct
  from the Lua 5.4 build in tier 8, which is for libinput specifically, not
  interchangeable), uchardet (tier 11), vulkan-loader (tier 4)

**Tier 15 — Firefox**
- `firefox` `[BLFS xsoft/firefox.html]` — required: cbindgen (tier 6), gtk3,
  libnotify, libarchive, llvm+clang (tier 6), nodejs (already built),
  pulseaudio, startup-notification (all tier 11); recommended: dav1d, libaom,
  libvpx (tier 12), icu, libevent, nss (tier 11), libwebp (tier 2), nasm
  (tier 12)
- Optional dep worth calling out: ffmpeg itself is Firefox's optional runtime
  dep for playing mov/mp3/mp4 — already built by tier 13, so Firefox gets
  that for free by build order

**LLVM+clang decision, resolved 2026-08-26**: earlier in this session, LLVM
was deliberately *not* built as its own BLFS package when building Rust --
Rust was configured to use its own bundled/vendored copy instead, avoiding
a separate multi-hour, multi-GB LLVM build. That was scoped narrowly to
Rust's own needs. Firefox is a different case: its book page lists
`LLVM-21.1.8 (with clang, used for bindgen even if using gcc)` as a hard
Required dependency, not something Firefox can bundle its own copy of.
Operator confirmed: build real LLVM+clang as its own package when Firefox
is reached, queued after Tier 12/13/14 (media codecs, ffmpeg, mpv) to avoid
CPU contention with those on this 4-core box.

## NVIDIA proprietary driver (opt-in, after the base stack is verified on nouveau)

- Fetch NVIDIA's archived 470.256.02 Linux driver `.run` installer
- Build its kernel module against the currently-running kernel's headers
- Re-run after every kernel rebuild (no DKMS on this system)
- Swap the active GL vendor via `libglvnd`'s `opengl-driver` mechanism

## Open questions before I start building

1. **nouveau-first, defer 470.256.02** — confirm the recommended order above,
   given the driver's real limitations on this Kepler-generation card.
2. **Fold `CONFIG_DRM_NOUVEAU` into the kernel rebuild in progress right now**
   (cheap, same rebuild) vs. a separate follow-up kernel change later.
3. **PulseAudio is a new subsystem, not a small dependency** — worth a beat to
   confirm before it's pulled in: audio server + policy daemon, required by
   both Firefox and mpv, on a box that's had no audio stack at all so far.

This is now a very large build — 70+ packages before Firefox/mpv/Hyprland
themselves link. Say the word and I'll start at Tier 1 once the netfilter
kernel work finishes.
