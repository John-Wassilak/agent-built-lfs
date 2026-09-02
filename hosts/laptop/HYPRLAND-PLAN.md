# Hyprland installation plan -- `laptop`

Goal: Hyprland (Wayland) with pipewire audio, on Intel HD Graphics 520 (Skylake GT2,
`i915`). Neither Wayland nor Hyprland exist in the BLFS 13.0 book, same as `server`.
Sourcing policy, same as `server`'s `HYPRLAND-PLAN.md`: BLFS recipe where the book has
one, otherwise Arch's official `extra` packaging as the build reference.

## Reusing server's work instead of rediscovering it

`server` built this exact stack against this exact book edition (13.0-systemd) before
abandoning it for X11 after its NVIDIA Kepler card made Wayland a dead end (commit
`7efd90e`, "Remove Hyprland/Wayland and nouveau now that X11/awesome/nvidia is stable").
Its `HYPRLAND-PLAN.md` and the pre-removal recipe tree (commit `9a4021b`) already answer
almost every question a from-scratch attempt would otherwise hit blind: exact versions,
undocumented transitive dependencies found only by letting real builds fail, and working
recipe content for everything BLFS itself doesn't cover.

This machine has no NVIDIA dead end -- Intel's `i915`/`iris`/`ANV` stack is fully open and
current -- so the plan is almost identical, with three substitutions:

- **`mesa`**: `gallium-drivers=iris`, `vulkan-drivers=intel` (real ANV Vulkan -- something
  server's Kepler card never got), `glvnd=disabled` (single GPU vendor, no need for
  libglvnd's vendor-neutral dispatch that server needed for nouveau/NVIDIA coexistence --
  skip `libglvnd` entirely).
- **Audio**: pipewire + `pipewire-pulse` as the actual target, not real PulseAudio --
  operator decision, unlike server which built both side by side. Deferred to its own
  phase after Hyprland core is working (see below); may still need PulseAudio's headers
  if something in the GTK3/Firefox chain hard-requires linking against them, decided when
  that tier is actually reached.
- **Ordering**: server's own seq numbers reflect *when* a step was added across several
  real sessions, not a clean linear build order -- e.g. its `blfs-xorg-env` is seq 120,
  long after the seq-37 `util-macros` step that actually needs `$XORG_PREFIX` already
  set. A fresh `--resume` run needs real dependency order from the start. Laptop's
  `packages.py` reorders for this; version numbers and recipe content are otherwise
  reused as-is.

## Scope for this pass -- explicitly NOT everything at once

Operator instruction (2026-08-30): Firefox/mpv/ffmpeg are wanted eventually, but not
built in the same pass as Hyprland. This plan stops at a working Hyprland + XWayland +
pipewire desktop. GTK3, PulseAudio, the media codec tier, mpv, ffmpeg, and Firefox are a
separate later phase -- tracked here so dependency decisions account for them (e.g. not
skipping a library Firefox will also need), but not built now.

## Tiers (dependency order; laptop's actual `packages.py` order, not server's seq history)

**Tier 1 -- build tooling + xorg-env**
`cmake`, then `xorg-env` (hand, sets `$XORG_PREFIX`/`$XORG_CONFIG` via profile.d --
every Xorg/XCB package below needs this already sourced, so it runs before any of them,
not after like server's history shows).

**Tier 2 -- low-level libs** (all real BLFS pages)
`abseil-cpp`, `brotli`, `highway`, `graphite2`, `giflib`, `libpng`, `lcms2`, `libjxl`,
`libwebp`, `pixman`, `freetype2`, `glib2`, `icu`, `harfbuzz`, `fontconfig`, `hwdata`,
`libdisplay-info`, `nettle`, `libtirpc`.

**Tier 3 -- X11/XCB core + the full legacy X11 lib set upfront**
Core: `util-macros`, `xorgproto`, `libXau`, `libXdmcp`, `xcb-proto`, `libxcb`, `libxcvt`,
`xcb-util` (all BLFS pages).

Legacy X11 libs server discovered one at a time via real build failures (XWayland,
vulkan-loader's X11 WSI, mesa's X11 platform, SDL3, at-spi2-core, pulseaudio all needed
these, undocumented in each page's own dependency list) -- built upfront here instead of
rediscovering each failure: `xtrans`, `libx11`, `libxext`, `libxrender`, `libxfixes`,
`libxcomposite`, `libxcursor`, `xcb-util-image`, `xcb-util-keysyms`,
`xcb-util-renderutil`, `xcb-util-wm`, `xcb-util-errors`, `libxscrnsaver`, `libice`,
`libsm`, `libxi`, `libxtst`, `xorg-font-util`, `libxkbfile`, `libfontenc`, `libxfont2`,
`libxrandr`, `libxshmfence`, `libxxf86vm`. All hand-authored (not in this BLFS mirror),
Arch's official PKGBUILDs as the build reference, same as server's.

**Tier 3.5 -- Wayland core** (BLFS pages)
`libxml2`, `wayland`, `wayland-protocols`, `xkeyboard-config`, `libxkbcommon`.

**Tier 4 -- GPU/GL stack**
`spirv-headers`, `spirv-tools`, `glslang`, `vulkan-headers`, `vulkan-loader`, `libdrm`
(BLFS pages), then `mesa` with this host's own `gallium-drivers=iris,
vulkan-drivers=intel, glvnd=disabled` (host override, `hosts/laptop/blfs-overrides.json`
-- same reason `blfs-mesa` is a host recipe on server: the driver scope is bound to the
GPU). `libepoxy` (BLFS page). No `libglvnd` -- single-vendor GPU, nothing to dispatch
between.

**Tier 6 -- Rust toolchain + Cairo/Pango** (BLFS pages; server's own note on skipping a
separate LLVM build for Rust and using its bundled copy applies equally here)
`libssh2`, `rust`, `cargo-c`, `cbindgen`, `cairo`, `fribidi`, `pango`,
`shared-mime-info`, `gdk-pixbuf`, `librsvg`, `libjpeg-turbo`, `muparser`.

**Tier 8 -- input & session management**
`libgudev`, `mtdev`, `libwacom` (BLFS pages); `libevdev`, `lua5.4`, `libinput`, `seatd`
(hand -- not in BLFS, Arch reference). `seatd`'s standalone server matters here too:
server found this system's lack of PAM means `systemd-logind` never sees a session, so
`seatd` needs its standalone server enabled, not just the logind-backed library.

**Tier 9 -- XWayland**
`dbus` (BLFS page), `libei`, `xwayland` (BLFS pages -- confirmed present in this book
mirror from server's own build, despite some of their own sub-deps not having pages).

**Tier 10 -- Hyprland ecosystem** (none in BLFS, all Arch `extra` reference, real
dependency chain -- order matters)
`libzip`, `pugixml`, `re2` (needs `abseil-cpp`, Tier 2), `tomlplusplus`,
`hyprwayland-scanner`, `hyprutils`, `hyprlang`, `hyprcursor`, `hyprgraphics`, `hyprwire`,
`hyprland-protocols`, `glaze`, `aquamarine`, `iniparser`, `hyprtoolkit`,
`hyprland-guiutils`, `lua5.5` (Hyprland's own hard dependency, distinct from Tier 8's
Lua 5.4 -- not ABI-compatible, coexist under separate pkg-config names), `hyprland`
itself.

Known gotchas from server's real build, expected to reproduce identically (same book,
same package versions): `hyprtoolkit` hard-requires `iniparser` undocumented anywhere;
Hyprland's CMakeLists hard-requires `wayland-protocols>=1.49` (matches the version
already pinned in Tier 3.5, no surprise this time) and `wayland-scanner>=1.25.0`; a
`std::ranges::starts_with` C++23 gap in this GCC's libstdc++ needed a one-line patch to
`src/helpers/MiscFunctions.cpp`'s `truthy()`. Applying the known fix proactively rather
than waiting to hit it again.

**Stop here for this pass.** Verify: `Hyprland --help` runs clean, `ldd` shows no missing
libraries, matching server's own verification (a real interactive session needs the
physical console, not this SSH-driven build).

## Tier 11 (pipewire) -- immediately after, since it's small and explicitly requested

`pciutils` (BLFS page, harmless prerequisite), `pipewire`, `wireplumber` (hand -- not in
BLFS, server's own hand recipes reused as-is, no GPU/audio-hardware-specific content in
either). No PulseAudio build in this pass; `pipewire-pulse` provides the compatibility
shim for anything that wants `libpulse`.

## Explicitly deferred (operator instruction: not this pass)

GTK3 + its prerequisites, PulseAudio (unless the GTK3/Firefox chain turns out to hard-link
against it rather than accept `pipewire-pulse`), the full media codec tier (dav1d,
libaom, libvpx, x264, x265, lame, libass, svt-av1, fdk-aac, libva, sdl3/sdl2-compat),
FFmpeg, mpv, LLVM+clang, Firefox. Revisit once Hyprland + pipewire is verified working.
