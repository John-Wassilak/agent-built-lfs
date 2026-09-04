# SPDX-License-Identifier: MIT
# agent-built-lfs -- BLFS build plan for `laptop`
# Copyright (c) 2026 John Wassilak

"""BLFS build plan for `laptop` -- nothing beyond the shared core yet.

BASE is the closure that makes an LFS system workable: CA store, Node.js for Claude
Code, ssh, curl/wget/git, sudo, iptables. It is what `server` was verified on, so it is
the right first target here too -- get to a box you can log into and run Claude Code on
before deciding anything about a desktop.

What to add after that, and what NOT to copy from `server`:

  seq 17-  server's desktop stack is NVIDIA 470.xx + VDPAU + NVENC and is wrong for any
           other GPU. The portable parts (X11 libs, fontconfig, harfbuzz, awesome, rofi,
           dunst, picom, alacritty) are shared recipes and can be lifted as-is. The
           GPU-bound ones -- mesa, ffmpeg, mpv, libvdpau, vdpauinfo, nv-codec-headers,
           nvidia-470xx -- live in hosts/server/recipes/ precisely because they cannot
           be. Expect to write hosts/laptop/recipes/blfs-mesa.sh (Intel: gallium-drivers
           =iris/crocus; AMD: radeonsi) and laptop ffmpeg/mpv recipes with VAAPI rather
           than VDPAU.
  new      things `server` has no reason to build: a battery/backlight/suspend story,
           wireless firmware and tooling, and a display-brightness key path.
  keep     intel-microcode is per-CPU, not portable: check /proc/cpuinfo's `bugs:` line
           on this machine and write its own recipe if old_microcode shows up.

Give every new step the next unused seq. Do not renumber existing entries.

seq 14.5 (adduser-john): BASE's own blfs-sudo step (seq 15) runs a shared override
(recipes/blfs-overrides.json) that does `usermod -aG wheel john` -- written when server
already had a live john account, created much later in server's real history via its own
hand(177, "adduser-john", ...). server's account predates that override text; a byte-for-
byte fresh build never actually exercised the real dependency order until laptop did,
2026-08-30: blfs-sudo failed outright with `usermod: user 'john' does not exist`. The
right long-term fix is arguably promoting user-creation into BASE itself, since the
override that assumes john already exists is already shared -- not done here because that
would inject a brand-new, never-run step into server's own live plan (server's john
already exists with a populated home directory; an unreviewed useradd step landing in its
--resume queue is not a risk worth taking without a separate, deliberate decision). Scoped
to laptop instead: the same shared hand-authored recipe server itself uses
(recipes/blfs-adduser-john.sh -- portable, no host-specific content), given a seq between
shell-startup-files (14) and sudo (15) so it runs first.
"""

from base import BASE, book, hand

# sorted(), not BASE + [...]: extract-blfs.py/build-plan.py execute list order as written,
# they do not re-sort by seq -- "keep the list sorted by seq" is a manual discipline that
# plain concatenation can't satisfy once a host needs an entry to interleave BEFORE an
# existing BASE step (adduser-john at 14.5 has to run before BASE's own sudo at 15).
#
# Hyprland/Wayland/pipewire stack, HYPRLAND-PLAN.md, Tiers 1-4 (2026-08-30). Versions and
# recipe content reused from server's own real build of this exact stack against this
# exact book edition (commit 9a4021b, before server abandoned it for X11) -- see
# HYPRLAND-PLAN.md for what's substituted (mesa's driver scope, no libglvnd) and why the
# ordering here is NOT server's own seq history (server's numbers reflect when a step was
# added across several sessions, not a clean dependency order -- xorg-env has to run
# before the Xorg-family packages that need $XORG_PREFIX, not long after them).
PACKAGES = sorted(BASE + [
    hand(14.5, "adduser-john", "", "adduser-john (hand-authored, shared recipe)"),

    # --- Tier 1: build tooling + xorg-env -------------------------------------
    book(17, "cmake", "general/cmake.html", "cmake-4.2.3.tar.gz"),
    hand(17.5, "xorg-env", "", "xorg-env (hand-authored, shared recipe)"),

    # --- Tier 2: low-level libs ------------------------------------------------
    book(18, "abseil-cpp", "general/abseil-cpp.html", "abseil-cpp-20260107.1.tar.gz"),
    book(19, "brotli", "general/brotli.html", "brotli-1.2.0.tar.gz"),
    book(20, "highway", "general/highway.html", "highway-1.3.0.tar.gz"),
    book(21, "graphite2", "general/graphite2.html", "graphite2-1.3.14.tgz"),
    book(22, "giflib", "general/giflib.html", "giflib-5.2.2.tar.gz"),
    book(23, "libpng", "general/libpng.html", "libpng-1.6.55.tar.xz"),
    book(24, "lcms2", "general/lcms2.html", "lcms2-2.18.tar.gz"),
    book(25, "libjxl", "general/libjxl.html", "libjxl-0.11.2.tar.gz"),
    book(26, "libwebp", "general/libwebp.html", "libwebp-1.6.0.tar.gz"),
    book(27, "pixman", "general/pixman.html", "pixman-0.46.4.tar.gz"),
    book(28, "freetype2", "general/freetype2.html", "freetype-2.14.1.tar.xz"),
    book(29, "glib2", "general/glib2.html", "glib-2.86.4.tar.xz"),
    book(30, "icu", "general/icu.html", "icu4c-78.2-sources.tgz"),
    book(31, "harfbuzz", "general/harfbuzz.html", "harfbuzz-12.3.2.tar.xz"),
    book(32, "fontconfig", "general/fontconfig.html", "fontconfig-2.17.1.tar.xz"),
    book(33, "hwdata", "general/hwdata.html", "hwdata-0.404.tar.gz"),
    book(34, "libdisplay-info", "general/libdisplay-info.html", "libdisplay-info-0.3.0.tar.xz"),
    book(35, "nettle", "postlfs/nettle.html", "nettle-3.10.2.tar.gz"),
    book(36, "libtirpc", "basicnet/libtirpc.html", "libtirpc-1.3.7.tar.bz2"),

    # --- Tier 3: X11/XCB core ---------------------------------------------------
    book(37, "util-macros", "x/util-macros.html", "util-macros-1.20.2.tar.xz"),
    book(38, "xorgproto", "x/xorgproto.html", "xorgproto-2025.1.tar.xz"),
    book(39, "libXau", "x/libXau.html", "libXau-1.0.12.tar.xz"),
    book(40, "libXdmcp", "x/libXdmcp.html", "libXdmcp-1.1.5.tar.xz"),
    book(41, "xcb-proto", "x/xcb-proto.html", "xcb-proto-1.17.0.tar.xz"),
    book(42, "libxcb", "x/libxcb.html", "libxcb-1.17.0.tar.xz"),
    book(43, "libxcvt", "x/libxcvt.html", "libxcvt-0.1.3.tar.xz"),
    book(44, "xcb-util", "x/xcb-util.html", "xcb-util-0.4.1.tar.xz"),

    # --- Tier 3 (cont.): legacy X11 libs server discovered piecemeal via real
    # failures (XWayland, vulkan-loader's X11 WSI, mesa's X11 platform, SDL3,
    # at-spi2-core, pulseaudio all needed these, undocumented in each page's own
    # dependency list) -- built upfront here instead of rediscovering each one.
    # None in this BLFS mirror; Arch's official PKGBUILDs as build reference.
    hand(45, "xtrans", "xtrans-1.6.0.tar.xz", "xtrans (hand-authored)"),
    hand(46, "libx11", "libX11-1.8.13.tar.xz", "libx11 (hand-authored)"),
    hand(47, "libxext", "libXext-1.3.7.tar.xz", "libxext (hand-authored)"),
    hand(48, "libxrender", "libXrender-0.9.12.tar.xz", "libxrender (hand-authored)"),
    hand(49, "libxfixes", "libXfixes-6.0.2.tar.xz", "libxfixes (hand-authored)"),
    hand(50, "libxcomposite", "libXcomposite-0.4.7.tar.xz", "libxcomposite (hand-authored)"),
    hand(51, "libxcursor", "libXcursor-1.2.3.tar.xz", "libxcursor (hand-authored)"),
    hand(52, "xcb-util-image", "xcb-util-image-0.4.1.tar.xz", "xcb-util-image (hand-authored)"),
    hand(53, "xcb-util-keysyms", "xcb-util-keysyms-0.4.1.tar.xz", "xcb-util-keysyms (hand-authored)"),
    hand(54, "xcb-util-renderutil", "xcb-util-renderutil-0.3.10.tar.xz", "xcb-util-renderutil (hand-authored)"),
    hand(55, "xcb-util-wm", "xcb-util-wm-0.4.2.tar.xz", "xcb-util-wm (hand-authored)"),
    hand(56, "xcb-util-errors", "xcb-util-errors-1.0.1.tar.xz", "xcb-util-errors (hand-authored)"),
    hand(57, "libxscrnsaver", "libXScrnSaver-1.2.5.tar.xz", "libxscrnsaver (hand-authored)"),
    hand(58, "libice", "libICE-1.1.2.tar.xz", "libice (hand-authored)"),
    hand(59, "libsm", "libSM-1.2.6.tar.xz", "libsm (hand-authored)"),
    hand(60, "libxi", "libXi-1.8.3.tar.xz", "libxi (hand-authored)"),
    hand(61, "libxtst", "libXtst-1.2.5.tar.xz", "libxtst (hand-authored)"),
    hand(62, "xorg-font-util", "font-util-1.4.1.tar.xz", "xorg-font-util (hand-authored)"),
    hand(63, "libxkbfile", "libxkbfile-1.2.0.tar.xz", "libxkbfile (hand-authored)"),
    hand(64, "libfontenc", "libfontenc-1.1.9.tar.xz", "libfontenc (hand-authored)"),
    hand(65, "libxfont2", "libXfont2-2.0.9.tar.xz", "libxfont2 (hand-authored)"),
    hand(66, "libxrandr", "libXrandr-1.5.5.tar.xz", "libxrandr (hand-authored)"),
    hand(67, "libxshmfence", "libxshmfence-1.3.3.tar.xz", "libxshmfence (hand-authored)"),
    hand(68, "libxxf86vm", "libXxf86vm-1.1.7.tar.xz", "libxxf86vm (hand-authored)"),

    # --- Tier 3.5: Wayland core --------------------------------------------------
    book(69, "libxml2", "general/libxml2.html", "libxml2-2.15.1.tar.xz"),
    book(70, "wayland", "general/wayland.html", "wayland-1.26.0.tar.xz"),
    book(71, "wayland-protocols", "general/wayland-protocols.html", "wayland-protocols-1.49.tar.xz"),
    book(72, "xkeyboard-config", "x/xkeyboard-config.html", "xkeyboard-config-2.46.tar.xz"),
    book(73, "libxkbcommon", "general/libxkbcommon.html", "libxkbcommon-1.13.1.tar.gz"),

    # --- Tier 4: GPU/GL stack. mesa's driver scope is Intel-specific -- see the
    # host override in blfs-overrides.json (gallium-drivers=iris,
    # vulkan-drivers=intel, glvnd=disabled -- single GPU vendor, no libglvnd needed
    # unlike server's nouveau/NVIDIA coexistence problem).
    book(74, "spirv-headers", "general/spirv-headers.html", "SPIRV-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    book(75, "spirv-tools", "general/spirv-tools.html", "SPIRV-Tools-vulkan-sdk-1.4.341.0.tar.gz"),
    book(76, "glslang", "x/glslang.html", "glslang-16.2.0.tar.gz"),
    book(77, "vulkan-headers", "x/vulkan-headers.html", "Vulkan-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    book(78, "vulkan-loader", "x/vulkan-loader.html", "Vulkan-Loader-vulkan-sdk-1.4.341.0.tar.gz"),
    book(79, "libdrm", "x/libdrm.html", "libdrm-2.4.131.tar.xz"),

    # mesa's own meson.build (with_driver_using_cl) unconditionally requires libclc
    # for gallium-drivers=iris and vulkan-drivers=intel -- not optional, not a
    # rusticl-only thing, discovered via a real meson configure failure 2026-08-30
    # ('Dependency "libclc" not found'). libclc needs spirv-llvm-translator, which
    # needs real LLVM+clang -- a genuinely heavy addition (server itself flagged
    # LLVM as "4.7GB, 3 extra tarballs, hours"), confirmed with the operator before
    # proceeding given only ~14G free at the time. Real BLFS pages for all three
    # (server's own packages.py mislabels spirv-llvm-translator/libclc as hand()
    # entries even though their recipe headers say book-extracted -- corrected here).
    # hand(), not book(): recipes/blfs-llvm.sh already exists, hand-authored (by an
    # earlier server session, still shared/portable -- no GPU-specific content),
    # and deliberately skips the book's PAM-dependent 19-SBU test suite. Declaring
    # this book() would have let the next real extraction overwrite it with a
    # fresh auto-generated candidate that brings that test suite back -- caught
    # before running the real (non-check) extraction, 2026-08-30.
    hand(79.1, "llvm", "llvm-21.1.8.src.tar.xz", "LLVM-21.1.8 with clang (hand-authored, shared recipe)"),
    book(79.2, "spirv-llvm-translator", "general/spirv-llvm-translator.html", "SPIRV-LLVM-Translator-21.1.4.tar.gz"),
    book(79.3, "libclc", "general/libclc.html", "libclc-21.1.8.src.tar.xz"),

    # Not in this BLFS mirror (general/python-modules.html covers dozens of Python
    # modules on one page, doesn't fit the one-page-per-package model). Required
    # by Mesa's build-time code generation scripts, discovered via a real meson
    # configure failure 2026-08-31 ('Python mako module >= 0.8.0 required').
    # Reused verbatim from server's own hand-authored recipe (portable, no
    # GPU-specific content); sourced from PyPI, sha256 verified.
    hand(79.4, "mako", "mako-1.3.10.tar.gz", "Mako (hand-authored, shared recipe)"),

    # Same situation as mako, checked at the same time to avoid a third
    # round-trip: mesa's meson.build has exactly two Python module checks
    # (grepped directly), mako and this one. Also required by Mesa's
    # build-time code generation. Reused from server's own recipe.
    hand(79.5, "pyyaml", "pyyaml-6.0.3.tar.gz", "PyYAML (hand-authored, shared recipe)"),

    # Reversing the earlier "skip libglvnd, single GPU vendor" call (see BUILD-REPORT.md):
    # aquamarine's CMakeLists links against OpenGL::OpenGL, the GLVND-specific target
    # CMake's FindOpenGL only creates when a real libOpenGL.so (GLVND's own dispatch
    # library) is present -- mesa's plain libGL.so alone, built with glvnd=disabled,
    # never produces it, vendor-count aside. Discovered 2026-08-31 via a real CMake
    # configure failure ('links to OpenGL::OpenGL ... but the target was not found').
    # GLVND turns out to be the expected baseline for this class of package, not an
    # optional multi-vendor extra. Server's own recipe, portable, no GPU-specific
    # content -- must build before mesa's rebuild below.
    hand(79.6, "libglvnd", "libglvnd-v1.7.0.tar.gz", "libglvnd (hand-authored, shared recipe)"),

    book(80, "mesa", "x/mesa.html", "mesa-25.3.5.tar.xz"),
    book(81, "libepoxy", "x/libepoxy.html", "libepoxy-1.5.10.tar.xz"),

    # --- Tier 6: Rust toolchain + Cairo/Pango. Rust links the already-built system
    # LLVM (host override, blfs-overrides.json) rather than bundling its own copy --
    # server skipped that for its own first Rust build since it hadn't built LLVM
    # yet; laptop already paid that cost for mesa's libclc. Rust/cargo-c/cbindgen/
    # librsvg all need live DNS inside the chroot for stage0/crates.io fetches --
    # the resolv.conf fix is now a shared override (recipes/blfs-overrides.json),
    # promoted there once it was clearly a repo-wide pattern, not laptop-specific.
    book(82, "libssh2", "general/libssh2.html", "libssh2-1.11.1.tar.gz"),
    book(83, "rust", "general/rust.html", "rustc-1.93.1-src.tar.xz"),
    book(84, "cargo-c", "general/cargo-c.html", "cargo-c-0.10.20.tar.gz"),
    book(85, "cbindgen", "general/cbindgen.html", "cbindgen-0.29.2.tar.gz"),
    book(86, "cairo", "x/cairo.html", "cairo-1.18.4.tar.xz"),
    book(87, "fribidi", "general/fribidi.html", "fribidi-1.0.16.tar.xz"),
    book(88, "pango", "x/pango.html", "pango-1.57.0.tar.xz"),
    book(89, "shared-mime-info", "general/shared-mime-info.html", "shared-mime-info-2.4.tar.gz"),

    # libjpeg-turbo before gdk-pixbuf: gdk-pixbuf's meson.build hard-requires
    # libjpeg ('Dependency libjpeg is required but not found') -- an ordering bug
    # from this session, not a book gap, caught 2026-08-31 before either step had
    # actually completed. gdk-pixbuf before librsvg: librsvg's own rsvg-pixbuf.h
    # header hard #includes gdk-pixbuf/gdk-pixbuf.h even though librsvg's book page
    # lists it only as Recommended -- server's real discovery, applies identically.
    book(89.5, "libjpeg-turbo", "general/libjpeg.html", "libjpeg-turbo-3.1.3.tar.gz"),
    book(90, "gdk-pixbuf", "x/gdk-pixbuf.html", "gdk-pixbuf-2.44.5.tar.xz"),
    book(91, "librsvg", "general/librsvg.html", "librsvg-2.61.4.tar.xz"),
    book(93, "muparser", "lxqt/muparser.html", "muparser-2.3.5.tar.gz"),

    # --- Tier 8: input & session management. libevdev/lua5.4/libinput/seatd not in
    # BLFS -- Arch's official PKGBUILDs as build reference, recipe content reused
    # verbatim from server's own real build of this exact stack (commit 9a4021b,
    # before it was removed for X11). seatd's standalone server matters: this
    # system has no PAM, so systemd-logind never sees a session -- seatd needs its
    # own standalone server enabled, not just the logind-backed library.
    book(94, "libgudev", "general/libgudev.html", "libgudev-238.tar.xz"),
    book(95, "mtdev", "general/mtdev.html", "mtdev-1.1.7.tar.bz2"),

    # libevdev before libwacom: libwacom's meson.build requires it, another
    # ordering bug from this session's own first draft, not a book gap -- caught
    # 2026-08-31 before libwacom had actually completed.
    hand(95.5, "libevdev", "libevdev-1.13.7.tar.gz", "libevdev (hand-authored, shared recipe)"),
    book(96, "libwacom", "general/libwacom.html", "libwacom-2.18.0.tar.xz"),
    hand(98, "lua5.4", "lua-5.4.9.tar.gz", "lua5.4 (hand-authored, shared recipe)"),
    hand(99, "libinput", "libinput-1.31.3.tar.gz", "libinput (hand-authored, shared recipe)"),
    hand(100, "seatd", "seatd-0.9.3.tar.gz", "seatd (hand-authored, shared recipe)"),

    # --- Tier 9: XWayland. All real BLFS pages, confirmed present in this mirror.
    book(101, "dbus", "general/dbus.html", "dbus-1.16.2.tar.xz"),
    book(102, "libei", "x/libei.html", "libei-1.5.0.tar.bz2"),
    book(103, "xwayland", "x/xwayland.html", "xwayland-24.1.9.tar.xz"),

    # --- Tier 10: the Hyprland ecosystem itself. None in BLFS, all Arch `extra`
    # reference, real dependency chain (order matters) -- exact order and versions
    # reused from server's own proven build. iniparser placed right before
    # hyprtoolkit: server found hyprtoolkit hard-requires it via pkg-config,
    # undocumented in every Hyprland-ecosystem PKGBUILD. lua5.5 is Hyprland's own
    # hard Lua dependency, distinct from Tier 8's lua5.4 (libinput's device-quirk
    # scripts) -- not ABI-compatible, coexist under separate pkg-config names.
    hand(104, "libzip", "libzip-1.11.4.tar.xz", "libzip (hand-authored, shared recipe)"),
    hand(105, "pugixml", "pugixml-1.16.tar.gz", "pugixml (hand-authored, shared recipe)"),
    hand(106, "re2", "re2-2025-11-05.tar.gz", "re2 (hand-authored, shared recipe)"),
    hand(107, "tomlplusplus", "tomlplusplus-3.4.0.tar.gz", "tomlplusplus (hand-authored, shared recipe)"),
    hand(108, "hyprwayland-scanner", "hyprwayland-scanner-0.4.6.tar.gz", "hyprwayland-scanner (hand-authored, shared recipe)"),
    hand(109, "hyprutils", "hyprutils-0.14.1.tar.gz", "hyprutils (hand-authored, shared recipe)"),
    hand(110, "hyprlang", "hyprlang-0.6.8.tar.gz", "hyprlang (hand-authored, shared recipe)"),
    hand(111, "hyprcursor", "hyprcursor-0.1.13.tar.gz", "hyprcursor (hand-authored, shared recipe)"),
    hand(112, "hyprgraphics", "hyprgraphics-0.5.1.tar.gz", "hyprgraphics (hand-authored, shared recipe)"),
    hand(113, "hyprwire", "hyprwire-0.3.1.tar.gz", "hyprwire (hand-authored, shared recipe)"),
    hand(114, "hyprland-protocols", "hyprland-protocols-0.7.0.tar.gz", "hyprland-protocols (hand-authored, shared recipe)"),
    hand(115, "glaze", "glaze-8.1.0.tar.gz", "glaze (hand-authored, shared recipe)"),
    hand(116, "aquamarine", "aquamarine-0.14.0.tar.gz", "aquamarine (hand-authored, shared recipe)"),
    hand(117, "iniparser", "iniparser-4.2.6.tar.gz", "iniparser (hand-authored, shared recipe)"),
    hand(118, "hyprtoolkit", "hyprtoolkit-0.5.4.tar.gz", "hyprtoolkit (hand-authored, shared recipe)"),
    hand(119, "hyprland-guiutils", "hyprland-guiutils-0.2.2.tar.gz", "hyprland-guiutils (hand-authored, shared recipe)"),
    hand(120, "lua5.5", "lua-5.5.1.tar.gz", "lua5.5 (hand-authored, shared recipe)"),
    hand(121, "hyprland", "source-v0.56.2.tar.gz", "Hyprland-0.56.2 (hand-authored, shared recipe)"),

    # --- Tier 11: pipewire audio, the operator's explicit target (not PulseAudio).
    # All three recipes reused verbatim from server -- real BLFS pages, mislabeled
    # hand() there (like spirv-llvm-translator/libclc in Tier 4) but content is
    # portable and not GPU/host-specific, so kept as hand() here too rather than
    # re-deriving from the book for no benefit. PulseAudio is only "Recommended" on
    # pipewire's own book page for migration/coexistence -- pipewire-pulse (the
    # actual PulseAudio-compatible service) builds and works without real
    # PulseAudio installed, confirmed by reading the book page directly, matching
    # the operator's pipewire-not-pulseaudio instruction with no build-time cost.
    hand(122, "pciutils", "pciutils-3.14.0.tar.gz", "pciutils-3.14.0 (hand-authored, shared recipe)"),
    hand(123, "pipewire", "pipewire-1.6.0.tar.bz2", "pipewire-1.6.0 (hand-authored, shared recipe)"),
    hand(124, "wireplumber", "wireplumber-0.5.13.tar.bz2", "Wireplumber-0.5.13 (hand-authored, shared recipe)"),

    # --- Tier 11: GTK3 + audio codec prerequisites. All real BLFS pages. PulseAudio
    # deliberately NOT included here -- confirmed by reading x/gtk3.html directly
    # that GTK3 itself has no PulseAudio dependency at all (Required: at-spi2-core,
    # gdk-pixbuf, libepoxy, Pango -- all already built). server's own Tier 11 bundled
    # PulseAudio into the same wave because mpv/Firefox need it, not GTK3 -- both are
    # still out of scope for this pass, so PulseAudio stays deferred until whichever
    # of them is actually reached.
    book(125, "libogg", "multimedia/libogg.html", "libogg-1.3.6.tar.xz"),
    book(126, "flac", "multimedia/flac.html", "flac-1.5.0.tar.xz"),
    book(127, "opus", "multimedia/opus.html", "opus-1.6.1.tar.gz"),
    book(128, "libvorbis", "multimedia/libvorbis.html", "libvorbis-1.3.7.tar.xz"),
    book(129, "libsndfile", "multimedia/libsndfile.html", "libsndfile-1.2.2.tar.xz"),
    book(130, "alsa-lib", "multimedia/alsa-lib.html", "alsa-lib-1.2.15.3.tar.bz2"),
    book(131, "speex", "multimedia/speex.html", "speex-1.2.1.tar.gz"),
    book(132, "gsettings-desktop-schemas", "gnome/gsettings-desktop-schemas.html", "gsettings-desktop-schemas-49.1.tar.xz"),
    book(133, "at-spi2-core", "x/at-spi2-core.html", "at-spi2-core-2.58.3.tar.xz"),
    book(134, "gtk3", "x/gtk3.html", "gtk-3.24.51.tar.xz"),

    # --- Tier 12: media codec libraries, for the ffmpeg/mpv tier ahead. All real
    # BLFS pages. nasm first -- build tool Recommended by several of the rest.
    # libva particularly relevant on this GPU: VAAPI hardware video accel through
    # mesa's iris driver, unlike server which only ever had VDPAU (NVIDIA).
    book(135, "nasm", "general/nasm.html", "nasm-3.01.tar.xz"),
    book(136, "libusb", "general/libusb.html", "libusb-1.0.29.tar.bz2"),
    book(137, "dav1d", "multimedia/dav1d.html", "dav1d-1.5.3.tar.gz"),
    book(138, "libaom", "multimedia/libaom.html", "libaom-3.13.1.tar.gz"),
    book(139, "libvpx", "multimedia/libvpx.html", "libvpx-1.16.0.tar.gz"),
    book(140, "x264", "multimedia/x264.html", "x264-20250815.tar.xz"),
    book(141, "x265", "multimedia/x265.html", "x265_4.1.tar.gz"),
    book(142, "lame", "multimedia/lame.html", "lame-3.100.tar.gz"),
    book(143, "libass", "multimedia/libass.html", "libass-0.17.4.tar.xz"),
    book(144, "svt-av1", "multimedia/svt-av1.html", "SVT-AV1-v4.0.1.tar.gz"),
    book(145, "fdk-aac", "multimedia/fdk-aac.html", "fdk-aac-2.0.3.tar.gz"),
    book(146, "libva", "multimedia/libva.html", "libva-2.23.0.tar.gz"),
    book(147, "sdl3", "multimedia/sdl3.html", "SDL3-3.4.0.tar.gz"),
    book(148, "sdl2-compat", "multimedia/sdl2.html", "sdl2-compat-2.32.64.tar.gz"),

    # --- Tier 13-14: FFmpeg + mpv. Real BLFS pages -- server mislabeled these
    # hand() too (same pattern as spirv-llvm-translator/libclc/pciutils/pipewire/
    # wireplumber). PulseAudio deliberately skipped for both: confirmed by reading
    # both book pages directly that ffmpeg lists it Optional (not Required), and
    # while mpv's book prose lists it Required, mpv's own meson build command has
    # no explicit -D pulse=/-D alsa= flags at all -- both are meson 'auto' features
    # that silently skip if absent, never hard-fail. alsa-lib (Tier 11) + pipewire
    # (Tier 11, also a real "Optional Audio Output Driver" on mpv's own dependency
    # list) give mpv working audio without real PulseAudio, matching the operator's
    # pipewire-not-pulseaudio instruction with no build-time cost -- same
    # verify-before-building approach as the pipewire tier itself.
    # Real BLFS page (server mislabeled hand() too). Required by libplacebo for
    # its OpenGL header generation at build time -- discovered via a real meson
    # configure failure ('glad ... was not found'), not documented as a hard
    # dependency on libplacebo's own page (Python module install, pip3 wheel).
    book(148.5, "glad", "general/glad.html", "glad-2.0.8.tar.gz"),
    book(149, "libplacebo", "multimedia/libplacebo.html", "libplacebo-7.360.0.tar.gz"),
    book(150, "ffmpeg", "multimedia/ffmpeg.html", "ffmpeg-8.0.1.tar.xz"),
    book(151, "luajit", "general/luajit.html", "luajit-20260213.tar.xz"),
    book(152, "uchardet", "general/uchardet.html", "uchardet-0.0.8.tar.xz"),
    # Not in this BLFS mirror. mpv's meson.build hard-requires it (X11 Present
    # extension, tear-free presentation) -- discovered via a real configure
    # failure, undocumented on mpv's own page (only lists generic Xorg
    # Libraries). Server's own recipe, portable, Arch's libXpresent as reference.
    hand(152.5, "libxpresent", "libXpresent-1.0.2.tar.xz", "libXpresent-1.0.2 (hand-authored, shared recipe)"),
    book(153, "mpv", "multimedia/mpv.html", "mpv-0.41.0.tar.gz"),

    # --- Firefox and its remaining deps. All real BLFS pages. LLVM+clang already
    # satisfied by Tier 4's llvm build (built "with clang" from the start, for
    # libclc) -- no separate LLVM rebuild needed here, unlike server which built
    # LLVM without clang first (for Rust) and needed a second build for Firefox.
    # PulseAudio: book lists it Required "(or alsa-lib if you edit the mozconfig;
    # now deprecated by mozilla)" but names no exact flag -- proceeding without
    # PulseAudio and without a forced audio flag first (alsa-lib + pipewire both
    # already present), matching this project's own practice of resolving a real
    # configure failure with the real error rather than guessing a flag ahead of
    # time (see the gallium-opencl lesson, Tier 4).
    book(154, "libnotify", "x/libnotify.html", "libnotify-0.8.8.tar.xz"),
    book(155, "libarchive", "general/libarchive.html", "libarchive-3.8.5.tar.xz"),
    book(156, "startup-notification", "x/startup-notification.html", "startup-notification-0.12.tar.gz"),
    book(157, "nspr", "general/nspr.html", "nspr-4.38.2.tar.gz"),
    book(158, "nss", "postlfs/nss.html", "nss-3.120.1.tar.gz"),
    book(159, "libevent", "basicnet/libevent.html", "libevent-2.1.12-stable.tar.gz"),
    # Not previously needed by anything in this build (X11-legacy libs came in for
    # XWayland/mpv, none of them pulled this one in transitively) -- discovered via
    # Firefox's own configure failing on a combined X11 pkg-config check ('Package
    # xdamage was not found'). Server hit the exact same gap building its own
    # Firefox and already has a hand-authored recipe recorded for it; reused as-is.
    hand(159.5, "libxdamage", "libXdamage-1.1.7.tar.xz", "libXdamage-1.1.7 (hand-authored, shared recipe)", page="x7lib"),
    book(160, "firefox", "xsoft/firefox.html", "firefox-140.8.0esr.source.tar.xz"),

    # --- Requested 2026-09-01: cryptsetup, sshfs, wireguard -- not part of the
    # Hyprland/desktop stack, queued once the build pipeline was free again. Server
    # built this exact same chain already (packages.py seq 70-74, 196); versions and
    # recipes matched directly rather than rediscovered.
    # libaio: the book's own download URL (pagure.io/libaio/archive/...) 404s --
    # upstream moved to codeberg.org/jmoyer/libaio since this book mirror was
    # captured, confirmed by server hitting the same dead link first. Fetched from
    # https://codeberg.org/jmoyer/libaio/archive/libaio-0.3.113.tar.gz instead (no
    # md5 to verify against -- the book's checksum was for the dead mirror's file).
    book(161, "libaio", "general/libaio.html", "libaio-0.3.113.tar.gz"),
    book(162, "json-c", "general/json-c.html", "json-c-0.18.tar.gz"),
    book(163, "popt", "general/popt.html", "popt-1.19.tar.gz"),
    book(164, "lvm2", "postlfs/lvm2.html", "LVM2.2.03.38.tgz"),
    book(165, "cryptsetup", "postlfs/cryptsetup.html", "cryptsetup-2.8.4.tar.xz"),
    # FUSE_FS/CUSE added to bin/kernel-config-base.sh (shared -- generic kernel
    # feature, not per-host) alongside this. Kernel needs a rebuild before sshfs
    # can actually mount anything, same two-step as cryptsetup's DM_CRYPT gap.
    book(166, "fuse", "postlfs/fuse.html", "fuse-3.18.1.tar.gz"),
    book(167, "sshfs", "postlfs/sshfs.html", "sshfs-3.7.5.tar.xz"),
    # Not in BLFS -- no dedicated wireguard-tools chapter in this book mirror. The
    # kernel module (CONFIG_WIREGUARD) is already in the shared base config; this
    # is only the userspace wg/wg-quick CLI. Server's hand-authored recipe (git
    # upstream, matching Arch's wireguard-tools version at the time) reused as-is.
    hand(168, "wireguard-tools", "wireguard-tools-1.0.20260223.tar.xz", "wireguard-tools-1.0.20260223 (hand-authored, shared recipe)"),

    # --- Requested 2026-09-01: carry over the live host's actual network stack.
    # NetworkManager is what genuinely provides WiFi on this machine today (active,
    # managing real saved networks) but was never in this build's plan at all --
    # without it the deployed laptop would have no way onto WiFi out of the box.
    # Tailscale is also live and actively managing DNS on the host. Chain built in
    # dependency order: go (tailscale needs it) -> tailscale; duktape -> polkit;
    # libnl -> wpa_supplicant; libndp -> NetworkManager; libgudev/libusb already
    # present (Tier 8-10) -> upower -> thermald.
    #
    # Polkit built WITHOUT its Recommended PAM support: PAM is not Required (only
    # duktape+GLib are), and the book's own PAM page warns that installing
    # Linux-PAM requires Shadow and Systemd to be reinstalled/reconfigured
    # afterward for it to actually take effect -- a much larger, riskier change
    # than "add WiFi", on a system whose login/su/sudo already all work. Skipped;
    # can be revisited separately if desktop session-tracking polish is wanted.
    hand(169, "go", "go1.27.0.src.tar.gz", "go1.27.0 (hand-authored, shared recipe)"),
    hand(170, "tailscale", "tailscale-v1.102.3.tar.gz", "tailscale-1.102.3 (hand-authored, shared recipe)"),
    book(171, "duktape", "general/duktape.html", "duktape-2.7.0.tar.xz"),
    book(172, "polkit", "postlfs/polkit.html", "polkit-127.tar.gz"),
    book(173, "libnl", "basicnet/libnl.html", "libnl-3.12.0.tar.gz"),
    book(174, "wpa_supplicant", "basicnet/wpa_supplicant.html", "wpa_supplicant-2.11.tar.gz"),
    book(175, "libndp", "basicnet/libndp.html", "libndp-1.9.tar.gz"),
    book(176, "networkmanager", "basicnet/networkmanager.html", "NetworkManager-1.56.0.tar.xz"),
    book(177, "upower", "general/upower.html", "upower-v1.91.1.tar.bz2"),
    # Not in BLFS -- ThinkPad thermal management (fan/throttle tuning), matches
    # what the live host actually runs. See recipes/blfs-thermald.sh for the two
    # autoconf-archive/gtk-doc patches this needed, both verified against the
    # real source before trusting them.
    hand(178, "thermald", "thermald-2.5.12.tar.gz", "thermald-2.5.12 (hand-authored, shared recipe)"),

    # --- Requested 2026-09-01: emacs, screen, sshd/iptables actually enabled at boot.
    # sshd.service was never actually enabled for this host at all (openssh has been
    # installed since BASE, but nothing ever ran `make install-sshd` from the BLFS
    # systemd-units package) -- a real, previously-unnoticed gap: this host has had no
    # way to accept an SSH connection this entire build. Fixed alongside the requested
    # iptables-unit addition since both come from the same shared source package.
    book(179, "jansson", "general/jansson.html", "jansson-2.15.0.tar.bz2"),
    book(180, "libtiff", "general/libtiff.html", "tiff-4.7.1.tar.gz"),
    book(181, "gnutls", "postlfs/gnutls.html", "gnutls-3.8.12.tar.xz"),
    # emacs's Recommended deps (harfbuzz, giflib, cairo, dbus -- all already present;
    # jansson, libtiff, gnutls added directly above) all checked against this build,
    # not assumed present.
    book(182, "emacs", "postlfs/emacs.html", "emacs-30.2.tar.xz"),
    book(183, "screen", "general/screen.html", "screen-5.0.1.tar.gz"),
    # Both hand-authored, no BLFS book page of their own -- the book's own openssh.html
    # and iptables.html pages point at this shared blfs-systemd-units source package's
    # own Makefile targets ('make install-sshd' / 'make install-iptables') instead.
    # Real gap found while adding iptables-unit: sshd was never wired up either.
    hand(184, "sshd-unit", "blfs-systemd-units-20251204.tar.xz", "sshd-unit (hand-authored, shared recipe)"),
    hand(185, "iptables-unit", "blfs-systemd-units-20251204.tar.xz", "iptables-unit (hand-authored, shared recipe)"),
    # Host-specific (real key material, not portable) -- see
    # hosts/laptop/recipes/blfs-authorized-keys-john.sh. Must run after both
    # adduser-john (needs /home/john to exist) and sshd-unit (no reason to install
    # keys before sshd can even use them, though order isn't load-bearing either way).
    hand(186, "authorized-keys-john", "", "authorized-keys-john (hand-authored, host-specific)"),
    # Real gap found during /lfs-audit 2026-09-01: this step exists for server
    # (packages.py's own hand(117, "lfsmaint", ...)) but was never added here --
    # cpufreq-governor.service and lfsmaint-check.timer never existed for laptop at
    # all, and lfsmaint itself was never installed into the target's own /usr/sbin,
    # so the check timer would have had nothing to run even if it existed. The
    # governor gap is not cosmetic: server measured a 2.1x real-workload loss from
    # its absence. Packaged fresh (bin/lfsmaint + overlay/units/*.service/.timer +
    # a new install.sh) since server's own original lfsmaint-1.0.tar.gz was never
    # preserved anywhere in this repo for reuse.
    hand(187, "lfsmaint", "lfsmaint-1.0.tar.gz", "lfsmaint-1.0 (hand-authored, shared recipe)"),
    # Not in BLFS -- requested, user-level (not system-wide) npm install for john.
    # Node.js already in BASE (seq 6). No tarball: npm does its own fetching from
    # the registry at build time (needs the same DNS fix as every other live-fetch
    # recipe in this build).
    hand(188, "claude-code", "", "claude-code (hand-authored, shared recipe, user-level npm install)"),

    # --- USB boot test, 2026-09-02 (BUILD-REPORT.md): dmesg.out/lspci.out from booting
    # /mnt/usb showed the Intel Wireless 8260 totally unassociated (15x iwlwifi ucode
    # load failures, "no suitable firmware found!") and i915 disabling runtime power
    # management for the same reason -- host.toml's own [hardware] wifi note already
    # flagged the need for these blobs, but no step for them ever existed. Both fetch a
    # single blob from the LFS Project's own mirror (BLFS's postlfs/firmware.html),
    # same narrow-fetch policy as server's hand(172, "linux-firmware-rtl-nic", ...).
    hand(189, "linux-firmware-iwlwifi-8260", "", "linux-firmware-iwlwifi-8260 (hand-authored, host-specific)"),
    hand(190, "linux-firmware-i915-dmc", "", "linux-firmware-i915-dmc (hand-authored, host-specific)"),

    # Same USB boot test: the wired NIC (e1000e/enp0s31f6) itself probed clean in
    # dmesg, but nmcli reported it unreachable -- traced to systemd-networkd
    # (LFS 13.0-systemd's default) still being enabled alongside NetworkManager (seq
    # 176, added 2026-09-01), leaving two managers eligible to own the same links.
    # Host-specific: server deliberately keeps plain systemd-networkd with no
    # NetworkManager, so this is not a shared decision. Must run after networkmanager
    # (176) so NetworkManager's own enable step has already happened.
    hand(191, "laptop-network-manager-only", "", "laptop-network-manager-only (hand-authored, host-specific)"),

    # Same USB boot test: operator requested usbutils/lsusb for further hardware
    # diagnosis. Real book page (general/usbutils.html); deps libusb/hwdata already
    # built (Tier 8-12, see the NetworkManager block above).
    book(192, "usbutils", "general/usbutils.html", "usbutils-019.tar.xz"),

    # Found live, testing the new start-hyprland.sh launcher (2026-09-03):
    # XWayland's embedded X server fails to init its virtual keyboard --
    # "sh: /usr/bin/xkbcomp: No such file or directory", "XKB: Failed to
    # compile keymap", "Fatal server error: Failed to activate virtual core
    # keyboard". Not in BLFS; server already hit and fixed this exact gap
    # (hand(197, ...) there) but it was never carried over here. Shared
    # recipe (recipes/blfs-xkbcomp.sh) reused verbatim -- deps (libxkbfile,
    # xorgproto) already built (Tier 9).
    hand(193, "xkbcomp", "xkbcomp-xkbcomp-1.5.0.tar.gz", "xkbcomp-1.5.0 (hand-authored)"),

    # Found live, testing the real start-hyprland.sh session (2026-09-03, operator
    # watching the actual screen): `fc-list` returned zero fonts anywhere on this
    # system -- every glyph rendered as a tofu box ("squares"). Same exact gap and
    # fix server already has (hand(206-207, ...) there, both shared recipes reused
    # verbatim) -- just never carried over. dejavu-fonts is the general Latin/
    # Greek/Cyrillic fallback; jetbrains-mono-fonts because the operator's mirrored
    # alacritty.toml explicitly configures "JetBrains Mono" as the terminal font.
    hand(194, "dejavu-fonts", "dejavu-fonts-ttf-2.37.tar.bz2", "DejaVu fonts 2.37 (hand-authored)", page="TTF-and-OTF-fonts"),

    # JetBrains' own release asset is a .zip; bin/lfsbuild's generic unpack step
    # is `tar -xf` unconditionally, no zip support (confirmed: GNU tar 1.35 here
    # refuses it outright, "This does not look like a tar archive"). Server's own
    # "completed" build of this exact step must predate this gap or worked around
    # it outside the driver -- not visible in the current recipe either way.
    # Re-packed the same official release contents into
    # JetBrainsMono-2.304.tar.gz (unzip then tar -cz, same top-level dir name) so
    # this flows through the normal pipeline; recipe itself (fonts/ttf/*.ttf) is
    # unchanged and still applies to the re-tarred layout.
    hand(195, "jetbrains-mono-fonts", "JetBrainsMono-2.304.tar.gz", "JetBrains Mono 2.304 (hand-authored)", page="TTF-and-OTF-fonts"),

    # Same live session: operator's SUPER+Return (alacritty) and SUPER+D (wofi)
    # keybindings, both mirrored from the real dotfiles into hyprland.lua, did
    # nothing -- neither binary was ever built here. Rust/Cargo project, tier 6's
    # toolchain already present; shared recipe (recipes/blfs-alacritty.sh) reused
    # verbatim from server.
    hand(196, "alacritty", "alacritty-0.17.0.tar.gz", "alacritty-0.17.0 (hand-authored)"),

    # wofi: never built anywhere in this project successfully -- server's own
    # attempt was part of the Hyprland/Wayland branch abandoned for X11/awesome
    # (recipe recovered from git history, commit 7efd90e^:recipes/blfs-wofi.sh,
    # never actually run to completion there). First real build of this recipe.
    # Bundles its own wlr-layer-shell protocol code -- no gtk-layer-shell
    # dependency (confirmed in the recipe's own rationale by reading meson.build).
    # Real deps: gtk+-3.0, wayland-client, gio-unix-2.0 -- all already present
    # (gtk+-3.0 came in as a Firefox dependency, not deliberately built for this).
    hand(197, "wofi", "wofi-v1.5.3.tar.gz", "wofi-1.5.3 (hand-authored)"),

    # Operator-requested (2026-09-03). Not in BLFS; shared recipe reused verbatim from
    # server (hand(175, ...) there) -- portable, no GPU/host-specific content. Deps
    # (libcap, ncursesw) already present.
    hand(198, "htop", "", "htop (hand-authored)"),

    # Operator-requested (2026-09-03): DankMaterialShell, which needs Quickshell,
    # which needs Qt6. Real BLFS page. Disk/CPU cost flagged and acknowledged before
    # starting (book's own estimate: 50GB build space, 12 SBU at parallelism=8; this
    # host has 2 jobs and ~41GB free) -- proceeding per operator instruction, watching
    # free space as the build goes, same as this host's own deploy strategy.
    book(199, "qt6", "x/qt6.html", "qt-everywhere-src-6.10.2.tar.xz"),

    # Operator-requested (2026-09-03): pavucontrol, to configure sound (pipewire-pulse
    # emulates the PulseAudio server protocol, but nothing here ever built a PulseAudio
    # *client* library or the GTK4 stack pavucontrol itself needs). Full chain, in
    # dependency order, all real BLFS pages. gobject-introspection and vulkan-loader
    # are both already present (confirmed live, not assumed) so gtk4's book-default
    # `-D introspection=enabled -D vulkan=enabled` needs no override, unlike the
    # NetworkManager/polkit overrides from 2026-09-01 written before introspection was
    # ever built here.
    book(200, "iso-codes", "general/iso-codes.html", "iso-codes-v4.20.1.tar.gz"),
    book(201, "graphene", "x/graphene.html", "graphene-1.10.8.tar.xz"),
    book(202, "libsigc++3", "general/libsigc3.html", "libsigc++-3.6.0.tar.xz"),
    book(203, "glibmm2", "general/glibmm2.html", "glibmm-2.86.0.tar.xz"),
    book(204, "cairomm", "x/cairomm-1.16.html", "cairomm-1.18.0.tar.xz"),
    book(205, "pangomm2", "x/pangomm2.html", "pangomm-2.56.1.tar.xz"),

    # Found live: gtk4's meson.build hard-requires xinerama ("Dependency 'xinerama'
    # not found"), undocumented in gtk4.html's own dependency list. Not in BLFS;
    # same hand-authored recipe server already has (hand(229, ...) there, for the
    # same reason -- dunst's own dependency on server), reused verbatim.
    hand(205.5, "libxinerama", "libXinerama-1.1.5.tar.xz", "libXinerama-1.1.5 (hand-authored)"),
    book(206, "gtk4", "x/gtk4.html", "gtk-4.20.3.tar.xz"),
    book(207, "gtkmm4", "x/gtkmm4.html", "gtkmm-4.20.0.tar.xz"),
    book(208, "json-glib", "general/json-glib.html", "json-glib-1.10.8.tar.xz"),

    # PulseAudio here for its client library (libpulse) only -- pavucontrol links
    # against it to talk to whatever implements the PulseAudio protocol, which is
    # already pipewire-pulse, matching this project's standing pipewire-not-
    # pulseaudio decision. Built via the book's own unmodified recipe (no meson
    # option to build client-only), but pulseaudio.service is never enabled/started
    # -- pipewire-pulse keeps being the actual running daemon, this package's
    # server binary just sits on disk unused, same as any other library package that
    # happens to also ship a daemon it doesn't get to run.
    book(209, "pulseaudio", "multimedia/pulseaudio.html", "pulseaudio-17.0.tar.xz"),
    book(210, "pavucontrol", "multimedia/pavucontrol.html", "pavucontrol-6.2.tar.xz"),

    # Found live, testing mpv --hwdec=vaapi with a real GPU vo (2026-09-03): both
    # VAAPI backend candidates failed to open --
    # "libva: Trying to open /usr/lib/dri/iHD_drv_video.so ... va_openDriver()
    # returns -1", same for i965_drv_video.so -- because neither file exists at
    # all. Root cause: this project's own seq-146 comment ("VAAPI hardware video
    # accel through mesa's iris driver") was a misconception -- mesa's iris is the
    # OpenGL/Vulkan driver; Intel VAAPI decode needs a separate driver package,
    # not part of mesa. `libva` (the dispatch library) was built, but never the
    # actual backend. intel-media-driver (iHD) is Intel's current-recommended
    # backend for Gen8+ (this is Gen9/Skylake), over the older intel-vaapi-driver
    # (i965). Kernel-side requirement (book's own note) already satisfied:
    # DRM_I915 is already enabled and working. gmmlib is intel-media-driver's own
    # Required dependency (Intel's graphics memory management library).
    book(211, "gmmlib", "general/gmmlib.html", "gmmlib-22.8.2.tar.gz"),
    book(212, "intel-media-driver", "multimedia/intel-media-driver.html", "intel-media-driver-25.3.4.tar.gz"),

    # Operator-requested (2026-09-03): pass (the standard Unix password manager). Same
    # chain server already built (its own seq 75-83, 171) -- not in BLFS itself, but its
    # full dependency tree is, and versions match this book snapshot exactly (checked
    # against book/blfs-13.0 directly, not assumed from server's history). Confirmed
    # live: none of gpg/pinentry/tree exist on this host yet.
    book(213, "libgpg-error", "general/libgpg-error.html", "libgpg-error-1.59.tar.bz2"),
    book(214, "libgcrypt", "general/libgcrypt.html", "libgcrypt-1.12.0.tar.bz2"),
    book(215, "libassuan", "general/libassuan.html", "libassuan-3.0.2.tar.bz2"),
    book(216, "libksba", "general/libksba.html", "libksba-1.6.7.tar.bz2"),
    book(217, "npth", "general/npth.html", "npth-1.8.tar.bz2"),
    book(218, "openldap", "server/openldap.html", "openldap-2.6.12.tgz"),
    book(219, "pinentry", "general/pinentry.html", "pinentry-1.3.2.tar.bz2"),
    book(220, "gnupg", "postlfs/gnupg.html", "gnupg-2.5.17.tar.bz2"),
    book(221, "tree", "general/tree.html", "unix-tree-2.3.1.tar.bz2"),

    # Same hand-authored recipe server uses (recipes/blfs-pass.sh) reused verbatim --
    # portable, no host-specific content, same source (git.zx2c4.com/password-store
    # snapshot, not BLFS/AUR).
    hand(222, "pass", "password-store-1.7.4.tar.xz", "pass (hand-authored)"),

    # Operator-requested (2026-09-03): Bluetooth. Kernel side (CONFIG_BT and friends,
    # confirmed missing live -- see kernel-config.sh) is the other half of this; bluez
    # is the userspace stack. Its own Required deps: dbus/glib2 already present on this
    # host, libical is not (real BLFS page, nothing pulled it in before now).
    book(223, "libical", "general/libical.html", "libical-3.0.20.tar.gz"),
    book(224, "bluez", "general/bluez.html", "bluez-5.86.tar.xz"),

    # Operator-requested (2026-09-04): Quickshell + DankMaterialShell. Neither is in
    # BLFS. qt6 (seq 199, already queued 2026-09-03) is trimmed via a host override
    # (blfs-overrides.json) from the book's own ~30-module default down to the 5
    # submodules Quickshell/DMS actually import (checked against DMS's real QML
    # source, not docs) -- the book's default is what ate ~40GB and got killed
    # 2026-09-03; this should be a small fraction of that. Build order: qt6 first
    # (already queued below this point in seq but must run before these three),
    # then cli11 (quickshell's own build dependency), quickshell, then matugen and
    # dankmaterialshell (both need quickshell on PATH; matugen is standalone Rust,
    # order between the two doesn't matter, kept together for narrative clarity).
    hand(225, "cli11", "CLI11-2.7.2-Source.tar.gz", "CLI11-2.7.2 (hand-authored)"),
    hand(226, "quickshell", "quickshell-0.3.1.tar.gz", "quickshell-0.3.1 (hand-authored)"),
    hand(227, "matugen", "", "matugen (hand-authored, cargo install)"),
    hand(228, "dankmaterialshell", "", "DankMaterialShell-1.6.0 (hand-authored, git clone)"),
], key=lambda p: p["seq"])
