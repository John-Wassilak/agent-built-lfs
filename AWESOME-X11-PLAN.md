# X11 + awesome migration plan

Goal: replace Hyprland/Wayland with a working X11 desktop (`awesome` window
manager) on the NVIDIA 470.xx proprietary driver, to get real VDPAU H.264
hardware decode for the security-camera-viewing workload. Neither
`xorg-server` (the standalone X server, distinct from the already-built
`Xwayland`) nor `awesome` exist in the BLFS 13.0 book. Sourcing policy:
BLFS recipe where the book has one, Arch's official packaging otherwise
(matching this project's standing convention).

## Why awesome, why X11, why not Hyprland

Established this session (see `BUILD-REPORT.md`'s GPU deep-dive section for
the full investigation):

- nouveau's VAAPI H.264 decode has a real, unfixed upstream bug (Mesa
  gitlab #14058, filed against this exact GPU, zero maintainer engagement
  since October 2025). Not fixable from this side.
- The NVIDIA 470.xx proprietary driver (last branch supporting this GPU,
  Kepler/GK104) genuinely works -- patched and tested against this kernel,
  `nvidia-smi` and DRM/KMS registration both confirmed real hardware
  initialization, not just a clean compile.
- It predates GBM support (added in driver 495, years after Kepler was
  frozen on 470.xx) -- only has the older EGLStreams mechanism. Tested
  directly: Hyprland fails cleanly (`kmsro: driver missing` -> `CBackend::
  create() failed!`) because aquamarine has no EGLStreams path, confirmed
  live, not just predicted.
- EGLStreams as a concept is a dead end across the whole Wayland ecosystem,
  not just Hyprland: KDE/KWin implemented it (2019) then removed it (2021)
  after finding it "has several session breaking issues anyway"; GNOME/
  Mutter still has it but is dropping it in the imminent GNOME 51 release.
  No viable long-term Wayland compositor option exists for this driver.
- X11 is what the 470.xx branch was actually designed for and still works
  reliably there -- NVIDIA's own `nvidia_drv.so` Xorg driver module is
  already installed (from the driver install done earlier this session).

`awesome` chosen over `bspwm+sxhkd`/`i3` (operator decision, 2026-08-26):
Lua-configured, matching the config language this project's Hyprland setup
already used throughout (`hl.config()`/`hl.bind()` style) -- most direct
conceptual carryover. Built-in dynamic tiling (fair/tile layouts, closest
analog to Hyprland's dwindle), gaps support, and a built-in bar/systray
(`wibox`) that removes the need for a separate waybar-equivalent tool.
Lighter build than Hyprland too -- no Rust/exotic toolchain, just Lua,
cairo, pango, and X11 libraries, nearly all of which are already built.

## Phase 1: standalone Xorg server

Dependency check against the running system (done 2026-08-26, not
guessed): `pixman-1` (0.46.4), `libxcvt` (0.1.3), `xkeyboard-config`
(2.46), `libepoxy`, `libtirpc` (1.3.7), `libinput` (1.31.3), `libevdev`
(1.13.7), `mtdev` (1.1.7) are all already built and satisfy xorg-server's
required+recommended dependency list. Only genuinely new packages needed:

1. **xorg-server-21.1.21** (real BLFS book page, `x/xorg-server.html`).
   Standard meson build: `-D glamor=true -D xkb_output_dir=/var/lib/xkb`.
   Note: the book's `modesetting_drv` driver is what nouveau/generic DRM
   setups use -- irrelevant here, since we'll load NVIDIA's own
   `nvidia_drv.so` (already installed) instead. Installs `Xorg`, `Xvfb`,
   `Xnest`, `gtf`, optionally `Xephyr`.
2. **xorg-libinput-driver-1.5.0** (real BLFS book page, part of
   `x7driver.html`) -- the actual X11 input driver module wrapping
   `libinput` (which is already built). Without this, Xorg has no
   keyboard/mouse input.
3. **xinit-1.4.4** (real BLFS book page, `xinit.html`) -- provides
   `startx`/`xinit`, the standard X11 session-launch mechanism. Simpler
   than Hyprland's custom launcher script situation -- this is exactly
   what X11 was designed around from the start.

Test: `startx` with a trivial `.xinitrc` (e.g. just `xterm` or `xclock` --
both book-documented, tiny, good smoke tests) under the NVIDIA driver
(GRUB entry 1, `nouveau` blacklisted, `nvidia-drm modeset=1` loaded
manually as done in tonight's test). Confirms basic X11 + NVIDIA modeset
works before adding any WM complexity on top.

## Phase 2: awesome window manager

Not in BLFS. Check Arch's official `extra` repo first (standing sourcing
policy) -- `awesome` is Arch's official package, version to be confirmed
at build time via `pacman -Si awesome` or the Arch package web page, not
guessed here.

Dependencies (from Arch's PKGBUILD, to verify against what's already
built before assuming anything missing): Lua (5.3 or 5.4 -- this project
already has `lua5.4`/`luajit` built for Hyprland's own config engine,
need to confirm awesome's exact Lua version requirement), cairo (built),
pango (built), gdk-pixbuf (built), libxcb + xcb-util family (built),
libxdg-basedir, libstartup-notification (likely already built, was a
Hyprland dependency too -- `startup-notification` appeared in the earlier
shared-file sweep), imagemagick (optional, for `awesome-client`/theming
tools), gobject-introspection (for the `Lgi` Lua GObject bindings some
awesome widgets use, optional).

Config: `~/.config/awesome/rc.lua`. Port the *spirit* of the existing
Hyprland keybindings (terminal launch, launcher, workspace switching,
window focus/swap/resize, screenshots, volume) rather than translating
line-by-line -- awesome's API and concepts (tags instead of workspaces,
clients instead of windows) don't map 1:1.

## Phase 3: supporting utilities (X11 replacements for Wayland-only tools)

None of these are BLFS book pages -- all hand-authored, Arch-packaging
sourced, same pattern as the Hyprland-era equivalents:

| Wayland tool (Hyprland era) | X11 replacement | Notes |
|---|---|---|
| wofi (launcher) | rofi | Most popular X11 launcher, dmenu-compatible, more features than wofi had |
| mako (notifications) | dunst | The de facto X11-world standard, same minimal philosophy as mako |
| wl-clipboard + cliphist | xclip/xsel + clipmenu | clipmenu is the closest analog to cliphist (dmenu/rofi-driven clipboard history) |
| hyprshot (screenshots) | maim + slop | maim for capture, slop for interactive region selection -- matches the existing PRINT/SUPER+PRINT/SUPER+SHIFT+PRINT bindings |
| wlsunset (blue light) | redshift | Direct X11 equivalent, same purpose |

Deferred, not core to this plan: a compositor (`picom`) for rounded
corners/transparency. The operator's Hyprland config already had
blur/shadow disabled, so this isn't replacing a feature actually in use
-- add later only if wanted.

`alacritty` (terminal) and `mpv` need no replacement -- both already
support X11 natively (alacritty via winit's X11 backend, mpv via its
existing `vo=gpu` path), no rebuild needed. Firefox is X11-native by
default too.

## Phase 4: testing

Boot into GRUB entry 1 (nouveau blacklisted), load `nvidia-drm
modeset=1`, `startx` into `awesome`, confirm:
- Basic window management works (open alacritty, move/resize/tile it)
- VDPAU decode actually works: `vdpauinfo` (needs building, from the
  `vdpauinfo` gitlab.freedesktop.org project -- not yet checked whether
  it's in BLFS, likely hand-authored) or directly `mpv --hwdec=vdpau`
  against `test.mp4`/`test.mkv`, confirm no crash and real hardware
  decode via `nvidia-smi`'s utilization readout during playback.
- Multiple simultaneous streams (the actual camera-feed use case) --
  confirm CPU load stays low and no crashes under sustained multi-stream
  load, not just a single clean playback.

## Phase 5: cleanup, only after acceptance

Not executed as part of this plan -- explicit final step once the
operator confirms the X11/awesome setup is accepted as the replacement.
Candidate packages to remove (Hyprland/Wayland-only, not shared with the
new stack) -- to be confirmed against `lfsmaint`'s actual file ownership
before removing anything, not assumed from this list alone:

- `hyprland`, `hyprlang`, `hyprcursor`, `hyprwayland-scanner`, `hyprwire`,
  `hyprtoolkit`, `hyprgraphics`, `hyprutils`, `aquamarine` (the whole
  hypr* ecosystem)
- `wofi`, `mako`, `wlsunset`, `wl-clipboard`, `cliphist`, `hyprshot`
- `xwayland` (only useful for running X11 apps under a Wayland
  compositor -- pointless with no Wayland compositor running)
- `wayland`, `wayland-protocols` (core Wayland libraries -- only if
  nothing else still links against them; double-check before removing)
- `seatd` (Wayland-style seat management; Xorg has its own privilege
  model and doesn't need it)
- `go` + toolchain: built solely for `cliphist`. Keep or remove is a
  judgment call -- it's a general-purpose toolchain that could have
  other uses, not automatically Hyprland-only the way the rest of this
  list is.

Explicitly NOT removed -- shared with the new X11 stack or otherwise
still needed: Mesa, libglvnd, the core X11 library family (libX11,
libxcb, etc. -- Xorg itself needs these), libinput/libevdev/mtdev
(also used by the new `xorg-libinput-driver`), fonts, mpv, alacritty,
firefox, pipewire/wireplumber/pulseaudio (audio, unrelated to display
server choice), wireguard-tools (unrelated), the NVIDIA 470.xx driver
and `libvdpau` (the whole point of this migration).

## Status

Not started. Plan written 2026-08-26, awaiting go-ahead to begin Phase 1.
