"""BLFS build plan for `server` -- the machine, not the repo.

BASE (packages/base.py) first, then everything this box specifically is: a Kepler GPU on
the proprietary NVIDIA 470.xx driver, X11 + awesome, a VDPAU/NVENC media stack, Firefox,
PipeWire, and the ops tooling (Go, Tailscale, OpenBao, OpenTofu).

Read this with hosts/server/BUILD-REPORT.md: the report is the narrative, this is the
ordered list the driver runs. HYPRLAND-PLAN.md and AWESOME-X11-PLAN.md explain the seq
gaps -- the Wayland/Hyprland tier was planned, numbered, and abandoned for X11 after the
NVIDIA 470.xx EGLStreams dead end, so those numbers are retired rather than reused.

Entries carrying no comment were added directly to the plan during the desktop phase;
their rationale is in the header of their own recipe file and in the build report.
"""

from base import BASE, book, hand

PACKAGES = BASE + [
    # --- Hyprland desktop stack, HYPRLAND-PLAN.md, Tier 1-2 (2026-08-25) -----------
    # Policy from here: install each package's own BLFS "Recommended" deps (not just
    # Required) where they're plausible for this box -- but ONE level, not a chase
    # down every recommended dep's own recommended deps forever. Concretely: cmake's
    # Recommended (curl/libarchive/libuv/nghttp2, for its network-fetch/archive
    # features) and glib2's Recommended (docutils/libxslt, for docs/an xslt binding)
    # are skipped -- neither affects anything Hyprland/Firefox/mpv/ffmpeg actually
    # use cmake or glib2 for. Documented per-package below where it matters more.
    book(17, "cmake", "general/cmake.html", "cmake-4.2.3.tar.gz"),
    book(19, "brotli", "general/brotli.html", "brotli-1.2.0.tar.gz"),
    book(20, "highway", "general/highway.html", "highway-1.3.0.tar.gz"),
    book(21, "graphite2", "general/graphite2.html", "graphite2-1.3.14.tgz"),
    book(22, "giflib", "general/giflib.html", "giflib-5.2.2.tar.gz"),
    book(23, "libpng", "general/libpng.html", "libpng-1.6.55.tar.xz"),
    book(24, "lcms2", "general/lcms2.html", "lcms2-2.18.tar.gz"),

    # libjxl: Required deps only (brotli, cmake, giflib, highway, lcms2,
    # libjpeg-turbo[Arch, added separately], libpng) -- all built above.
    book(25, "libjxl", "general/libjxl.html", "libjxl-0.11.2.tar.gz"),

    # libwebp: Recommended is libjpeg-turbo/libpng (have) + libtiff/sdl2-compat "for
    # improved 3D acceleration" -- not built yet (sdl2-compat is tier 11, libtiff
    # not otherwise needed), skipped rather than reordering the whole plan for a
    # 3D-acceleration enhancement to a still-image codec.
    book(26, "libwebp", "general/libwebp.html", "libwebp-1.6.0.tar.gz"),
    book(27, "pixman", "general/pixman.html", "pixman-0.46.4.tar.gz"),

    # freetype2: Recommended harfbuzz is circular (harfbuzz also recommends
    # freetype2) -- book's own bootstrap order is freetype2 first without it, which
    # is what this does; harfbuzz follows below and links against this freetype2.
    # which-2.23 already built (original Claude Code dependency chain).
    book(28, "freetype2", "general/freetype2.html", "freetype-2.14.1.tar.xz"),
    book(29, "glib2", "general/glib2.html", "glib-2.86.4.tar.xz"),
    book(30, "icu", "general/icu.html", "icu4c-78.2-sources.tgz"),
    book(31, "harfbuzz", "general/harfbuzz.html", "harfbuzz-12.3.2.tar.xz"),
    book(32, "fontconfig", "general/fontconfig.html", "fontconfig-2.17.1.tar.xz"),
    book(33, "hwdata", "general/hwdata.html", "hwdata-0.404.tar.gz"),
    book(35, "nettle", "postlfs/nettle.html", "nettle-3.10.2.tar.gz"),
    book(36, "libtirpc", "basicnet/libtirpc.html", "libtirpc-1.3.7.tar.bz2"),

    # --- Tier 3 prep: X11/XCB compat, pulled ahead of HYPRLAND-PLAN.md's Tier 5
    # because libxkbcommon (Tier 3) recommends libxcb, and the whole chain needs
    # $XORG_PREFIX/$XORG_CONFIG from x/xorg7.html -- see blfs-xorg-env below.
    book(37, "util-macros", "x/util-macros.html", "util-macros-1.20.2.tar.xz"),
    book(38, "xorgproto", "x/xorgproto.html", "xorgproto-2025.1.tar.xz"),
    book(39, "libXau", "x/libXau.html", "libXau-1.0.12.tar.xz"),
    book(40, "libXdmcp", "x/libXdmcp.html", "libXdmcp-1.1.5.tar.xz"),
    book(41, "xcb-proto", "x/xcb-proto.html", "xcb-proto-1.17.0.tar.xz"),
    book(42, "libxcb", "x/libxcb.html", "libxcb-1.17.0.tar.xz"),
    book(43, "libxcvt", "x/libxcvt.html", "libxcvt-0.1.3.tar.xz"),
    book(44, "xcb-util", "x/xcb-util.html", "xcb-util-0.4.1.tar.xz"),

    # --- Tier 3: Wayland core ---
    book(45, "libxml2", "general/libxml2.html", "libxml2-2.15.1.tar.xz"),
    book(48, "xkeyboard-config", "x/xkeyboard-config.html", "xkeyboard-config-2.46.tar.xz"),
    book(49, "libxkbcommon", "general/libxkbcommon.html", "libxkbcommon-1.13.1.tar.gz"),

    # --- Tier 4: GPU/GL stack. Driver scope decided with the operator: only this
    # box's actual hardware (GTX 770, Kepler) plus a software fallback -- nouveau +
    # llvmpipe gallium drivers, swrast for Vulkan (no NVK/nouveau Vulkan: doubtful
    # Kepler support, and it would need rust-bindgen on top of everything else).
    # Not the book's own "auto" (all drivers, all vendors) default.
    book(50, "spirv-headers", "general/spirv-headers.html", "SPIRV-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    book(51, "spirv-tools", "general/spirv-tools.html", "SPIRV-Tools-vulkan-sdk-1.4.341.0.tar.gz"),
    book(52, "glslang", "x/glslang.html", "glslang-16.2.0.tar.gz"),
    book(53, "vulkan-headers", "x/vulkan-headers.html", "Vulkan-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    book(54, "vulkan-loader", "x/vulkan-loader.html", "Vulkan-Loader-vulkan-sdk-1.4.341.0.tar.gz"),
    book(55, "libdrm", "x/libdrm.html", "libdrm-2.4.131.tar.xz"),
    book(56, "mesa", "x/mesa.html", "mesa-25.3.5.tar.xz"),
    book(57, "libepoxy", "x/libepoxy.html", "libepoxy-1.5.10.tar.xz"),

    # --- Tier 6: Rust toolchain + Cairo/Pango. Decided with the operator to skip
    # building LLVM as its own package (4.7GB, 3 extra tarballs, hours) even though
    # Rust's bootstrap.toml recommends linking system LLVM -- Rust falls back to
    # its own bundled copy (book's own words: "the resulting build will be larger
    # and take longer", but avoids a second, separately-massive LLVM build on top).
    book(58, "libssh2", "general/libssh2.html", "libssh2-1.11.1.tar.gz"),
    book(59, "rust", "general/rust.html", "rustc-1.93.1-src.tar.xz"),
    book(60, "cargo-c", "general/cargo-c.html", "cargo-c-0.10.20.tar.gz"),
    book(61, "cbindgen", "general/cbindgen.html", "cbindgen-0.29.2.tar.gz"),
    book(62, "cairo", "x/cairo.html", "cairo-1.18.4.tar.xz"),

    # fribidi: pango's book page lists it as Required (Fontconfig, FriBidi-1.0.16,
    # GLib) -- missed adding it originally; discovered via a real pango meson failure.
    book(63, "fribidi", "general/fribidi.html", "fribidi-1.0.16.tar.xz"),
    book(64, "pango", "x/pango.html", "pango-1.57.0.tar.xz"),

    # gdk-pixbuf: librsvg's book page lists it only as Recommended, but librsvg's
    # own rsvg-pixbuf.h header hard #includes gdk-pixbuf/gdk-pixbuf.h -- the build
    # fails outright without it, discovered via a real librsvg meson/cc failure.
    # shared-mime-info is gdk-pixbuf's own Required dep, no deps beyond what's built.
    # Skipped gdk-pixbuf's other Recommended dep, glycin: circular (book says build
    # gdk-pixbuf without it first, then glycin, then rebuild gdk-pixbuf again) and a
    # heavy separate Rust image-loader stack -- out of scope for a one-level policy.
    book(65, "shared-mime-info", "general/shared-mime-info.html", "shared-mime-info-2.4.tar.gz"),
    book(66, "gdk-pixbuf", "x/gdk-pixbuf.html", "gdk-pixbuf-2.44.5.tar.xz"),
    book(67, "librsvg", "general/librsvg.html", "librsvg-2.61.4.tar.xz"),

    # libjpeg-turbo and muparser: both claimed "already built" in the Tier 10
    # hyprgraphics/hyprland rationale comments below but never actually added to
    # this list -- caught only by checking for their manifests before staging Tier
    # 10, same class of oversight as fribidi earlier. Both have real BLFS pages.
    book(68, "libjpeg-turbo", "general/libjpeg.html", "libjpeg-turbo-3.1.3.tar.gz"),
    book(69, "muparser", "lxqt/muparser.html", "muparser-2.3.5.tar.gz"),

    # --- Requested 2026-08-26: cryptsetup (disk encryption), not part of the
    # Hyprland stack -- queued alongside it since the build pipeline is already
    # running. Needs a kernel follow-up: CONFIG_BLK_DEV_DM/CRYPTO_AES/CRYPTO_SHA256
    # are already =y on 6.18.10-nftables, but CONFIG_DM_CRYPT, CONFIG_CRYPTO_XTS,
    # and CONFIG_CRYPTO_USER_API_SKCIPHER are not -- cryptsetup will build fine as
    # userspace tooling but can't actually open/create an encrypted volume until
    # those are added to kernel-config.sh and the kernel is rebuilt (batched with
    # the still-pending CONFIG_DRM_NOUVEAU addition noted in HYPRLAND-PLAN.md).
    # libaio: the book's download URL (pagure.io/libaio/archive/...) 404s -- upstream
    # moved to codeberg.org/jmoyer/libaio since this book mirror was captured. Fetched
    # from https://codeberg.org/jmoyer/libaio/archive/libaio-0.3.113.tar.gz instead
    # (confirmed via Arch's own libaio PKGBUILD, whose url= field points there now).
    # No md5 to verify against -- the book's checksum was for the dead mirror's file.
    book(70, "libaio", "general/libaio.html", "libaio-0.3.113.tar.gz"),
    book(71, "json-c", "general/json-c.html", "json-c-0.18.tar.gz"),
    book(72, "popt", "general/popt.html", "popt-1.19.tar.gz"),
    book(73, "lvm2", "postlfs/lvm2.html", "LVM2.2.03.38.tgz"),
    book(74, "cryptsetup", "postlfs/cryptsetup.html", "cryptsetup-2.8.4.tar.xz"),

    # --- Requested 2026-08-26: pass (the standard Unix password manager). Not in
    # BLFS itself; its own dependency chain (GnuPG + everything under it) is,
    # though -- pass just needs bash (have), gnupg, and tree at runtime.
    book(75, "libgpg-error", "general/libgpg-error.html", "libgpg-error-1.59.tar.bz2"),
    book(76, "libgcrypt", "general/libgcrypt.html", "libgcrypt-1.12.0.tar.bz2"),
    book(77, "libassuan", "general/libassuan.html", "libassuan-3.0.2.tar.bz2"),
    book(78, "libksba", "general/libksba.html", "libksba-1.6.7.tar.bz2"),
    book(79, "npth", "general/npth.html", "npth-1.8.tar.bz2"),
    book(80, "openldap", "server/openldap.html", "openldap-2.6.12.tgz"),
    book(81, "pinentry", "general/pinentry.html", "pinentry-1.3.2.tar.bz2"),
    book(82, "gnupg", "postlfs/gnupg.html", "gnupg-2.5.17.tar.bz2"),
    book(83, "tree", "general/tree.html", "unix-tree-2.3.1.tar.bz2"),

    # --- Tier 8: input & session management ---
    book(84, "libgudev", "general/libgudev.html", "libgudev-238.tar.xz"),
    book(85, "mtdev", "general/mtdev.html", "mtdev-1.1.7.tar.bz2"),
    book(86, "libwacom", "general/libwacom.html", "libwacom-2.18.0.tar.xz"),

    # --- Tier 9: XWayland. BLFS's own xwayland.html dependency list is much
    # leaner than Arch's equivalent package (which builds more optional
    # features) -- Required: libxcvt/pixman/wayland-protocols (have) + font-util;
    # Recommended: libepoxy/libtirpc/mesa (have). No libxfont2, libdecor, or the
    # rest of the legacy X11 lib set Arch's build pulls in but this one doesn't.
    book(87, "dbus", "general/dbus.html", "dbus-1.16.2.tar.xz"),

    # --- Tier 11: GTK3 + PulseAudio prerequisites (2026-08-26). All real BLFS
    # book pages. Chain: libogg -> flac/libvorbis/speex (Recommended/Required
    # deps of libsndfile and pulseaudio) -> libsndfile; gsettings-desktop-schemas
    # -> at-spi2-core -> gtk3; alsa-lib and speex Recommended by pulseaudio too.
    book(90, "libogg", "multimedia/libogg.html", "libogg-1.3.6.tar.xz"),
    book(91, "flac", "multimedia/flac.html", "flac-1.5.0.tar.xz"),
    book(92, "opus", "multimedia/opus.html", "opus-1.6.1.tar.gz"),
    book(93, "libvorbis", "multimedia/libvorbis.html", "libvorbis-1.3.7.tar.xz"),
    book(94, "libsndfile", "multimedia/libsndfile.html", "libsndfile-1.2.2.tar.xz"),
    book(95, "alsa-lib", "multimedia/alsa-lib.html", "alsa-lib-1.2.15.3.tar.bz2"),
    book(96, "speex", "multimedia/speex.html", "speex-1.2.1.tar.gz"),
    book(97, "gsettings-desktop-schemas", "gnome/gsettings-desktop-schemas.html", "gsettings-desktop-schemas-49.1.tar.xz"),
    book(98, "at-spi2-core", "x/at-spi2-core.html", "at-spi2-core-2.58.3.tar.xz"),
    book(99, "gtk3", "x/gtk3.html", "gtk-3.24.51.tar.xz"),
    book(100, "pulseaudio", "multimedia/pulseaudio.html", "pulseaudio-17.0.tar.xz"),

    # --- Tier 12: media codecs for FFmpeg/mpv (2026-08-26). All real BLFS book
    # pages. NASM built first -- Recommended by nearly everything else here.
    # Scope: FFmpeg's own Recommended list (not its much longer Optional list)
    # plus mpv's Required/Recommended, per the one-level Recommended-deps policy.
    book(101, "nasm", "general/nasm.html", "nasm-3.01.tar.xz"),
    book(102, "libusb", "general/libusb.html", "libusb-1.0.29.tar.bz2"),
    book(103, "dav1d", "multimedia/dav1d.html", "dav1d-1.5.3.tar.gz"),
    book(104, "libaom", "multimedia/libaom.html", "libaom-3.13.1.tar.gz"),
    book(105, "libvpx", "multimedia/libvpx.html", "libvpx-1.16.0.tar.gz"),
    book(106, "x264", "multimedia/x264.html", "x264-20250815.tar.xz"),
    book(107, "x265", "multimedia/x265.html", "x265_4.1.tar.gz"),
    book(108, "lame", "multimedia/lame.html", "lame-3.100.tar.gz"),
    book(109, "libass", "multimedia/libass.html", "libass-0.17.4.tar.xz"),
    book(110, "svt-av1", "multimedia/svt-av1.html", "SVT-AV1-v4.0.1.tar.gz"),
    book(111, "fdk-aac", "multimedia/fdk-aac.html", "fdk-aac-2.0.3.tar.gz"),
    book(112, "libva", "multimedia/libva.html", "libva-2.23.0.tar.gz"),
    book(113, "sdl3", "multimedia/sdl3.html", "SDL3-3.4.0.tar.gz"),
    book(114, "sdl2-compat", "multimedia/sdl2.html", "sdl2-compat-2.32.64.tar.gz"),

    # --- Requested 2026-08-26: GNU Screen. Not part of the Hyprland/media-codec
    # stack -- queued as a quick standalone build. No hard deps (book's own
    # configure already passes --disable-pam, so the Optional Linux-PAM dep
    # doesn't apply).
    book(115, "screen", "general/screen.html", "screen-5.0.1.tar.gz"),

    # The openssh page points at blfs-systemd-units for sshd.service; 'make install-sshd'
    # is that package's target, not openssh's.
    hand(116, "sshd-unit", "blfs-systemd-units-20251204.tar.xz", "sshd-unit (hand-authored)"),

    # Installs the maintenance tooling into the target: package database, security
    # advisory check, version drift, and a weekly timer. Packaged as a tarball so its
    # install is a tracked step like any other package.
    hand(117, "lfsmaint", "lfsmaint-1.0.tar.gz", "lfsmaint (hand-authored)"),

    # Remediation. ch07-createfiles block 5 was `exec /usr/bin/bash --login`, which
    # replaced the shell and silently discarded block 6 -- the block that creates the
    # login-accounting files. Re-running ch07-createfiles is NOT safe now: its `cat >
    # /etc/passwd` would delete the sshd user OpenSSH added and re-add the tester account
    # ch08-cleanup removed. So apply just the lost block.
    hand(118, "fix-varlog", "", "fix-varlog (hand-authored)"),

    # Installs Claude Code from npm. Needs working DNS inside the chroot, which the LFS
    # resolv.conf symlink cannot provide here.
    hand(119, "claude-code", "", "claude-code (hand-authored)"),

    # x/xorg7.html: every Xorg/XCB-family BLFS recipe from here on (util-macros,
    # xorgproto, libXau, libXdmcp, xcb-proto, libxcb, libxcvt, xcb-util, and later xorg-
    # xwayland) uses $XORG_PREFIX and $XORG_CONFIG in its literal build commands -- the
    # book has the reader export them once, persist them via /etc/profile.d, and reuse
    # throughout. No page-specific command block captures this since it is shared setup,
    # not part of any one package's page.
    hand(120, "xorg-env", "", "xorg-env (hand-authored)"),

    # Not in BLFS. libei's book page lists it as Required ('Required attrs-25.4.0') -- a
    # pure-Python package, same pip3-wheel pattern as pyyaml/mako, except *without* --no-
    # build-isolation: unlike pyyaml/mako (setuptools, already present), attrs' build
    # backend is hatchling, not installed -- discovered via a real 'Cannot import
    # hatchling.build' failure. Letting pip's normal isolated build fetch hatchling itself
    # (this target has direct internet access, confirmed by every curl fetch this session)
    # into a throwaway build venv is simpler and more honest than hand-vendoring hatchling
    # as its own recipe; the final `pip3 install` step of *this* package still installs
    # only the offline-built attrs wheel, no network involved. Sourced from PyPI directly
    # (files.pythonhosted.org), sha256 verified against PyPI's own published digest for
    # the 25.4.0 sdist.
    hand(122, "attrs", "attrs-25.4.0.tar.gz", "attrs (hand-authored)"),

    # Same situation as blfs-mako. Required by Mesa's build-time code generation scripts.
    # Its own Recommended deps (cython, libyaml, for C-accelerated parsing) skipped --
    # one-level policy, and this is a build-time tool only.
    hand(123, "pyyaml", "pyyaml-6.0.3.tar.gz", "pyyaml (hand-authored)"),

    # Not in this BLFS mirror. Header-only X transport library, required by libx11's
    # configure (discovered when libx11's build failed: 'Package xtrans not found').
    # Arch's official xtrans PKGBUILD as reference -- header-only, no compile step, just
    # configure + install.
    hand(124, "xtrans", "xtrans-1.6.0.tar.xz", "xtrans (hand-authored)"),

    # Not in this BLFS mirror at all (confirmed: no libX11.html anywhere under
    # book/blfs-13.0). Required by libglvnd (Arch's libglvnd PKGBUILD makedepends) and
    # Mesa's x11 platform support. Built per Arch's official libx11 PKGBUILD, using this
    # project's $XORG_CONFIG rather than Arch's own flags -- same convention as every
    # other Xorg lib already built (xorgproto, libXau, libXdmcp, etc).
    hand(125, "libx11", "libX11-1.8.13.tar.xz", "libx11 (hand-authored)"),

    # Same situation as blfs-libx11 -- not in this BLFS mirror, required by libglvnd and
    # Mesa's x11 platform. Arch's libxext PKGBUILD as reference.
    hand(126, "libxext", "libXext-1.3.7.tar.xz", "libxext (hand-authored)"),

    # Not in BLFS at all. Vendor-neutral GL/EGL/GLX dispatch -- the piece that lets Mesa's
    # nouveau path and (later, if installed) NVIDIA's proprietary libGL coexist and be
    # switched via the opengl-driver mechanism, rather than one unconditionally
    # overwriting the other's libGL.so. Arch's official libglvnd PKGBUILD as reference --
    # confirmed in extra, not AUR.
    hand(127, "libglvnd", "libglvnd-v1.7.0.tar.gz", "libglvnd (hand-authored)"),

    # Not in BLFS. Required by libinput. Arch's official libevdev PKGBUILD as reference.
    # tests=disabled added after a real build failure: the option defaults to enabled and
    # hard-requires the Check unit test framework, not installed.
    hand(128, "libevdev", "libevdev-1.13.7.tar.xz", "libevdev (hand-authored)"),

    # Not in BLFS (which only has LuaJIT). libinput's device-quirk scripts want Lua 5.4
    # specifically via pkg-config as 'lua5.4' -- distinct from the LuaJIT build mpv wants
    # later, not interchangeable. Adapted from Arch's official lua54 PKGBUILD, simplified:
    # skips Arch's parallel C++-linked lua++ variant (nothing here needs it) and the
    # lua5.4-style renamed binaries/libs (no other Lua version on this system to conflict
    # with) -- kept is exactly what matters for discovery: a lua5.4.pc pkg-config file
    # naming the real library, which is what libinput's meson.build actually probes for.
    # INSTALL_TOP=/usr added after a real failure: the upstream Makefile defaults
    # INSTALL_TOP to /usr/local, which put the actual lib/headers/binaries in /usr/local
    # while lua.pc (hardcoded prefix=/usr) pointed pkg-config at /usr -- a mismatch that
    # would have made libinput's dependency probe find the .pc file but not the library it
    # describes.
    hand(129, "lua5.4", "lua-5.4.9.tar.gz", "lua5.4 (hand-authored)"),

    # Not in BLFS. Recommended by Hyprland's own aquamarine backend and by libxkbcommon.
    # Arch's official libinput PKGBUILD as reference; no -D documentation flag needed --
    # it's a boolean option (not a feature like most other packages this session) already
    # defaulting to false, and passing 'disabled' to a boolean option is a hard meson
    # configure error (discovered via a real failure). tests=false added for the same
    # reason as libevdev's, though here the meson.build itself guards the Check dependency
    # with required:false so it wouldn't have hard-failed. debug-gui=false added after a
    # real failure: that boolean option also defaults to true and hard-requires GTK3/GTK4
    # for the libinput debug-events tool's GUI, neither of which is built yet on this
    # system (GTK3 is a later tier).
    hand(130, "libinput", "libinput-1.31.3.tar.gz", "libinput (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency (confirmed in Arch's official
    # hyprland PKGBUILD depends array: 'libxrender'), not just an XWayland transitive dep.
    hand(132, "libxrender", "libXrender-0.9.12.tar.xz", "libxrender (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency.
    hand(133, "libxfixes", "libXfixes-6.0.2.tar.xz", "libxfixes (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency, needs libxfixes (previous
    # step).
    hand(134, "libxcomposite", "libXcomposite-0.4.7.tar.xz", "libxcomposite (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency. Arch also lists 'default-
    # cursors' (a cursor-theme meta-package) as a runtime dep -- not a build requirement,
    # skipped; a cursor theme is a later, separate concern.
    hand(135, "libxcursor", "libXcursor-1.2.3.tar.xz", "libxcursor (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency, needs xcb-util (already built).
    hand(136, "xcb-util-image", "xcb-util-image-0.4.1.tar.xz", "xcb-util-image (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency.
    hand(137, "xcb-util-keysyms", "xcb-util-keysyms-0.4.1.tar.xz", "xcb-util-keysyms (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency.
    hand(138, "xcb-util-renderutil", "xcb-util-renderutil-0.3.10.tar.xz", "xcb-util-renderutil (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency.
    hand(139, "xcb-util-wm", "xcb-util-wm-0.4.2.tar.xz", "xcb-util-wm (hand-authored)"),

    # Not in this BLFS mirror. Direct Hyprland dependency.
    hand(140, "xcb-util-errors", "xcb-util-errors-1.0.1.tar.xz", "xcb-util-errors (hand-authored)"),

    # Not in this BLFS mirror. SDL3's cmake hard-requires it (X11 Screen Saver extension)
    # when X11 support is enabled -- discovered via a real configure failure ('Couldn't
    # find dependency package for XSCRNSAVER'), not mentioned in SDL3's book page (which
    # only lists the generic Xorg Libraries as part of Recommended). Arch's official
    # libxss PKGBUILD as reference -- needs libxext, libx11, xorgproto (all already
    # built).
    hand(141, "libxscrnsaver", "libXScrnSaver-1.2.5.tar.xz", "libxscrnsaver (hand-authored)"),

    # Not in this BLFS mirror. Required (hard) by pulseaudio's meson.build as 'ice' --
    # discovered via a real configure failure, not mentioned in pulseaudio's book page
    # beyond the generic 'Xorg Libraries' Recommended entry. Arch's official libice
    # PKGBUILD as reference -- needs xtrans, xorgproto (both already built).
    hand(142, "libice", "libICE-1.1.2.tar.xz", "libice (hand-authored)"),

    # Not in this BLFS mirror. Required (hard) alongside libice above by pulseaudio's
    # meson.build as 'sm', same undocumented-chain discovery. Arch's official libsm
    # PKGBUILD as reference -- needs libice (previous step), util-linux (already built in
    # LFS ch8), xorgproto.
    hand(143, "libsm", "libSM-1.2.6.tar.xz", "libsm (hand-authored)"),

    # Not in this BLFS mirror. Required by libXtst below (found via a real at-spi2-core
    # meson failure: 'Dependency xtst not found' -- at-spi2-core's book page only lists
    # the generic 'Xorg Libraries', not this specific transitive chain). Arch's official
    # libxi PKGBUILD as reference -- needs libxext, libxfixes, libx11, xorgproto (all
    # already built).
    hand(144, "libxi", "libXi-1.8.3.tar.xz", "libxi (hand-authored)"),

    # Not in this BLFS mirror. at-spi2-core hard-requires it (XTEST/RECORD extensions, for
    # accessibility input injection) -- not mentioned in the book's dependency list at
    # all, discovered via the same real failure as libxi above. Arch's official libxtst
    # PKGBUILD as reference -- needs libxext, libxi (previous step), libx11, xorgproto.
    hand(145, "libxtst", "libXtst-1.2.5.tar.xz", "libxtst (hand-authored)"),

    # Not in this BLFS mirror as its own page. xwayland.html lists it as a Required
    # dependency ('Xorg Fonts (only font-util)'). Arch's official xorg-font-util PKGBUILD
    # as reference.
    hand(146, "xorg-font-util", "font-util-1.4.2.tar.xz", "xorg-font-util (hand-authored)"),

    # Not in this BLFS mirror, and not listed in xwayland.html's documented dependency
    # list either -- discovered only via a real xwayland meson configure failure
    # ('Dependency xkbfile not found'); its meson.build hard-requires it with no
    # required:false guard, unlike the adjacent libbsd-overlay and xkbcomp checks in the
    # same block, which are genuinely optional. Arch's official libxkbfile PKGBUILD as
    # reference (meson-based, needs libx11 and xorgproto, both already built).
    hand(147, "libxkbfile", "libxkbfile-1.2.0.tar.xz", "libxkbfile (hand-authored)"),

    # Not in this BLFS mirror. Required by libXfont2 below (found the same way --
    # xwayland's meson.build hard-requires 'xfont2' with no book documentation of the
    # chain). Arch's official libfontenc PKGBUILD as reference. Its own runtime
    # dependency, xorg-fonts-encodings (encoding data tables), skipped: a data-only
    # package needed for actually rendering legacy X11 core fonts at runtime, not for
    # linking against the library, and this system has no legacy Xorg-Server installed to
    # use them -- one-level policy, out of scope.
    hand(148, "libfontenc", "libfontenc-1.1.9.tar.xz", "libfontenc (hand-authored)"),

    # Not in this BLFS mirror. Required (hard, unconditional) by xwayland's meson.build as
    # 'xfont2', undocumented in the book's dependency list. Arch's official libxfont2
    # PKGBUILD builds from a git tag and autoreconfs -- used the equivalent upstream
    # release tarball instead (same content, already carries a generated ./configure, no
    # autoreconf needed) since it's simpler and this mirror has no md5/sha to verify a git
    # checkout against anyway. No published checksum found for this tarball on
    # xorg.freedesktop.org (no .sha256sum/.sig companion file); fetched directly over
    # HTTPS and sanity-checked as a valid tar archive.
    hand(149, "libxfont2", "libXfont2-2.0.9.tar.xz", "libxfont2 (hand-authored)"),

    # Not in this BLFS mirror. Discovered when vulkan-loader's cmake configure failed:
    # 'required packages were not found: xrandr' -- vulkan-loader's X11 WSI backend needs
    # the RandR extension library to enumerate displays. Needs libxext, libxrender, libx11
    # (all already built). Arch's official libxrandr PKGBUILD as reference.
    hand(168, "libxrandr", "libXrandr-1.5.5.tar.xz", "libxrandr (hand-authored)"),

    # Not in this BLFS mirror. Discovered when mesa's meson configure failed: 'Dependency
    # xshmfence not found' -- needed for DRI3 support on the x11 platform. Arch's official
    # libxshmfence PKGBUILD as reference.
    hand(169, "libxshmfence", "libxshmfence-1.3.3.tar.xz", "libxshmfence (hand-authored)"),

    # Not in this BLFS mirror. Discovered when mesa's meson configure failed: 'Dependency
    # xxf86vm not found' -- the X11 platform's video-mode-switching support. Arch's
    # official libxxf86vm PKGBUILD as reference.
    hand(170, "libxxf86vm", "libXxf86vm-1.1.7.tar.xz", "libxxf86vm (hand-authored)"),

    # Not in BLFS. Checked AUR first per the standing two-tier policy -- not there either;
    # pass is popular enough for Arch's official 'extra' repo. Arch's own PKGBUILD source
    # is a git tag clone (git.zx2c4.com/password-store); fetched here via that same
    # server's own snapshot endpoint (git.zx2c4.com/password-store/snapshot/password-
    # store-1.7.4.tar.xz, verified reachable directly) rather than guessing a GitHub
    # mirror name. Needs bash (have), gnupg, tree (both just built).
    hand(171, "pass", "password-store-1.7.4.tar.xz", "pass (hand-authored)"),

    # Baseline hardware audit (2026-08-25) found 'r8169 0000:06:00.0: Unable to load
    # firmware rtl_nic/rtl8168e-3.fw (-2)' on every boot -- this is the machine's only
    # network interface. BLFS's 'About Firmware' page confirms the driver works without it
    # but says to install it once dmesg flags it missing. Fetches the one blob this NIC
    # needs from the LFS project's official mirror, not the full linux-firmware tree
    # (multi-GB, and the rest of it fixes hardware this box does not have).
    hand(172, "linux-firmware-rtl-nic", "", "linux-firmware-rtl-nic (hand-authored)"),

    # Baseline hardware audit (2026-08-25): CPU is an i5-2500K (family 6, model 42,
    # stepping 7 -> blob 06-2a-07) running microcode 0x28, applied once by the board's
    # 2012 BIOS and never updated. The kernel's own 'bugs:' line in /proc/cpuinfo lists
    # old_microcode and vmscape as unmitigated. BLFS's firmware.html is explicit that late
    # loading is no longer supported upstream (the kernel taints and warns on it) -- early
    # loading via a dedicated initrd is the only endorsed path. That reverses this
    # system's original no-initramfs design (see BUILD-REPORT.md), a deliberate call made
    # for this one purpose: the initrd carries nothing but this CPU's microcode blob, not
    # a general-purpose early-boot environment.
    hand(173, "intel-microcode", "", "intel-microcode (hand-authored)"),

    # iptables.html's 'Systemd Unit' section: 'install the iptables.service unit included
    # in the blfs-systemd-units package... make install-iptables'. Same package already
    # used for sshd.service (blfs-sshd-unit) -- that target lives in blfs-systemd-units'
    # own Makefile, not iptables', so it runs from this tree, separately. Unlike blfs-
    # sshd-unit (built during the original chroot build, where systemctl could not run),
    # this system is live now, so the Makefile's own 'systemctl enable' runs for real --
    # no DESTDIR trick needed.
    hand(174, "iptables-unit", "blfs-systemd-units-20251204.tar.xz", "iptables-unit (hand-authored)"),

    # Not in the BLFS 13.0 book (checked: no book/blfs-13.0 page mentions it). Checked AUR
    # first per the two-tier sourcing policy (BLFS when possible, else another distro's
    # packaging as a build reference) -- zero AUR results, because htop is popular enough
    # to live in Arch's official 'extra' repo instead. Build recipe below is adapted from
    # Arch's real PKGBUILD (gitlab.archlinux.org/archlinux/packaging/packages/htop),
    # cross-checked against htop's own configure.ac rather than trusted blindly: --enable-
    # sensors and --enable-delayacct need lm_sensors and libnl-3, neither installed here
    # and neither worth a separate package for two optional features that auto-disable
    # cleanly without them; --enable-openvz and --enable-vserver are in Arch's flag list
    # but do not exist as options in this htop version at all (dead flags, dropped here
    # rather than copied). --enable-capabilities (libcap) and --enable-unicode (ncursesw)
    # are kept -- both already present from the base LFS build.
    hand(175, "htop", "", "htop (hand-authored)"),

    # postlfs/vimrc.html's one example is a <pre class="screen"> block (the book's own
    # convention for 'not meant to be pasted verbatim', here just because vimrc comments
    # use " not #) -- the extractor only captures userinput/root blocks, so this doesn't
    # come through the normal pipeline and is quoted here by hand instead, verbatim from
    # the book. skel.html explicitly says the /etc/skel files 'can also copy... to the
    # home directory of any other user already in the system', root included -- root has
    # had no .bash_profile/.bashrc/.profile/.bash_logout since the original build (chapter
    # 4's versions were for the temporary lfs build user, not root) and was living
    # entirely off /etc/profile + /etc/bashrc.
    hand(176, "skel-vimrc-and-root", "", "skel-vimrc-and-root (hand-authored)"),

    # skel.html, 'When Adding a User': 'useradd -m <newuser>' -- -m copies /etc/skel into
    # the new home directory, which is the entire point of having just built it. UID/GID
    # land at 1000 (login.defs UID_MIN/GID_MIN, postlfs/users.html), the first ID above
    # LFS's system-account range. Password locked deliberately (usermod -L): decided with
    # the operator to create the account with no working auth yet rather than a temporary
    # password or a key sight-unseen -- sshd already allows password auth (blfs-openssh
    # block 5 was dropped for exactly this reason), so the account becomes reachable the
    # moment a password or authorized_keys is added, whenever that happens.
    hand(177, "adduser-john", "", "adduser-john (hand-authored)"),
    hand(178, "glad", "glad-2.0.8.tar.gz", "Glad-2.0.8 (hand-authored)"),
    hand(179, "libplacebo", "libplacebo-7.360.0.tar.gz", "libplacebo-7.360.0 (hand-authored)"),
    hand(179.5, "nv-codec-headers", "nv-codec-headers-11.1.5.3.tar.gz", "nv-codec-headers-11.1.5.3 (hand-authored, version-pinned to the 470.x driver)"),
    hand(180, "ffmpeg", "ffmpeg-8.0.1.tar.xz", "FFmpeg-8.0.1 (hand-authored)"),
    hand(181, "luajit", "luajit-20260213.tar.xz", "luajit-20260213 (hand-authored)"),
    hand(182, "uchardet", "uchardet-0.0.8.tar.xz", "uchardet-0.0.8 (hand-authored)"),
    hand(183, "mpv", "mpv-0.41.0.tar.gz", "mpv-0.41.0 (hand-authored)"),
    hand(184, "libxpresent", "libXpresent-1.0.2.tar.xz", "libXpresent-1.0.2 (hand-authored)"),
    hand(185, "nspr", "nspr-4.38.2.tar.gz", "NSPR-4.38.2 (hand-authored)"),
    hand(186, "nss", "nss-3.120.1.tar.gz", "NSS-3.120.1 (hand-authored)"),
    hand(187, "libarchive", "libarchive-3.8.5.tar.xz", "libarchive-3.8.5 (hand-authored)"),
    hand(188, "libnotify", "libnotify-0.8.8.tar.xz", "libnotify-0.8.8 (hand-authored)"),
    hand(189, "startup-notification", "startup-notification-0.12.tar.gz", "startup-notification-0.12 (hand-authored)"),
    hand(190, "libevent", "libevent-2.1.12-stable.tar.gz", "libevent-2.1.12 (hand-authored)"),
    hand(191, "llvm", "llvm-21.1.8.src.tar.xz", "LLVM-21.1.8 with clang (hand-authored)"),
    hand(192, "firefox", "firefox-140.8.0esr.source.tar.xz", "Firefox-140.8.0esr (hand-authored)"),
    hand(193, "pciutils", "pciutils-3.14.0.tar.gz", "pciutils-3.14.0 (hand-authored)"),
    hand(194, "pipewire", "pipewire-1.6.0.tar.bz2", "pipewire-1.6.0 (hand-authored)"),
    hand(195, "wireplumber", "wireplumber-0.5.13.tar.bz2", "Wireplumber-0.5.13 (hand-authored)"),
    hand(196, "wireguard-tools", "wireguard-tools-1.0.20260223.tar.xz", "wireguard-tools-1.0.20260223 (hand-authored)"),
    hand(197, "xkbcomp", "xkbcomp-xkbcomp-1.5.0.tar.gz", "xkbcomp-1.5.0 (hand-authored)"),
    hand(198, "jq", "jq-1.8.2.tar.gz", "jq-1.8.2 (hand-authored)"),
    hand(204, "alacritty", "alacritty-0.17.0.tar.gz", "alacritty-0.17.0 (hand-authored)"),
    hand(206, "dejavu-fonts", "dejavu-fonts-ttf-2.37.tar.bz2", "DejaVu fonts 2.37 (hand-authored)", page="TTF-and-OTF-fonts"),
    hand(207, "jetbrains-mono-fonts", "JetBrainsMono-2.304.zip", "JetBrains Mono 2.304 (hand-authored)", page="TTF-and-OTF-fonts"),
    hand(208, "hicolor-icon-theme", "hicolor-icon-theme-0.18.tar.xz", "hicolor-icon-theme-0.18"),
    hand(209, "usbutils", "usbutils-019.tar.xz", "usbutils-019"),
    hand(212, "libva-utils", "libva-utils-2.24.0.tar.gz", "libva-utils-2.24.0 (hand-authored)"),
    hand(214, "spirv-llvm-translator", "SPIRV-LLVM-Translator-21.1.4.tar.gz", "SPIRV-LLVM-Translator-21.1.4"),
    hand(215, "libclc", "libclc-21.1.8.src.tar.xz", "libclc-21.1.8"),
    hand(216, "vulkan-tools", "Vulkan-Tools-1.4.341.tar.gz", "Vulkan-Tools-1.4.341 (hand-authored)"),
    hand(217, "libvdpau", "libvdpau-1.5.tar.gz", "libvdpau-1.5 (hand-authored)"),
    hand(218, "nvidia-470xx", "NVIDIA-Linux-x86_64-470.256.02.run", "NVIDIA-Linux-x86_64-470.256.02 (hand-authored, experimental)"),
    hand(219, "libpciaccess", "libpciaccess-0.18.1.tar.xz", "libpciaccess-0.18.1 (hand-authored)"),
    hand(220, "xorg-server", "xorg-server-21.1.21.tar.xz", "Xorg-Server-21.1.21"),
    hand(221, "xf86-input-libinput", "xf86-input-libinput-1.5.0.tar.xz", "Xorg-Libinput-Driver-1.5.0", page="x7driver"),
    hand(222, "xinit", "xinit-1.4.4.tar.xz", "xinit-1.4.4"),
    hand(223, "libxdg-basedir", "libxdg-basedir-1.2.3.tar.gz", "libxdg-basedir-1.2.3 (hand-authored)"),
    hand(224, "xcb-util-cursor", "xcb-util-cursor-0.1.5.tar.xz", "xcb-util-cursor-0.1.5 (hand-authored)"),
    hand(225, "xcb-util-xrm", "xcb-util-xrm-1.3.tar.gz", "xcb-util-xrm-1.3 (hand-authored)"),
    hand(226, "imagemagick", "ImageMagick-7.1.2-13.tar.xz", "ImageMagick-7.1.2-13"),
    hand(227, "lua-lgi", "lgi-0.9.2.tar.gz", "lua-lgi-0.9.2 (hand-authored)"),
    hand(228, "awesome", "awesome-4.3.tar.gz", "awesome-4.3 (hand-authored)"),
    hand(229, "libxinerama", "libXinerama-1.1.5.tar.xz", "libXinerama-1.1.5 (hand-authored)"),
    hand(230, "rofi", "rofi-2.0.0.tar.gz", "rofi-2.0.0 (hand-authored)"),
    hand(231, "dunst", "dunst-1.13.2.tar.gz", "dunst-1.13.2 (hand-authored)"),
    hand(232, "redshift", "redshift-1.12.tar.xz", "redshift-1.12 (hand-authored)"),
    hand(233, "xsel", "xsel-1.2.1.tar.gz", "xsel-1.2.1 (hand-authored)"),
    hand(234, "clipnotify", "clipnotify-1.0.2.tar.gz", "clipnotify-1.0.2 (hand-authored)"),
    hand(235, "xdotool", "xdotool.tar.gz", "xdotool-4.20260303.1 (hand-authored)"),
    hand(236, "clipmenu", "clipmenu-6.2.0.tar.gz", "clipmenu-6.2.0 (hand-authored)"),
    hand(237, "libxt", "libXt-1.3.1.tar.xz", "libXt-1.3.1", page="x7lib"),
    hand(238, "libxmu", "libXmu-1.3.1.tar.xz", "libXmu-1.3.1", page="x7lib"),
    hand(239, "xauth", "xauth-1.1.5.tar.xz", "xauth-1.1.5", page="x7app"),
    hand(240, "vdpauinfo", "vdpauinfo-1.5.tar.gz", "vdpauinfo-1.5 (hand-authored)"),
    hand(241, "libxdamage", "libXdamage-1.1.7.tar.xz", "libXdamage-1.1.7 (hand-authored)", page="x7lib"),

    # Not in BLFS. Needed by hyprcursor (cursor theme archives are zip files). Arch's
    # official libzip PKGBUILD as reference; built against whatever of its optional
    # compression backends (zlib, bzip2, zstd, openssl) are actually present -- cmake
    # auto-detects and skips the rest, same pattern used throughout this build.
    hand(242, "libzip", "libzip-1.11.4.tar.xz", "libzip (hand-authored)"),
    hand(243, "libconfig", "libconfig-1.8.2.tar.gz", "libconfig-1.8.2 (hand-authored)"),
    hand(244, "libev", "libev-4.33.tar.gz", "libev-4.33 (hand-authored)"),
    hand(245, "uthash", "uthash-2.3.0.tar.gz", "uthash-2.3.0 (hand-authored)"),
    hand(246, "picom", "picom-v13.tar.gz", "picom-13 (hand-authored)"),
    hand(247, "smartmontools", "smartmontools-7.5.tar.gz", "smartmontools-7.5"),
    hand(248, "go", "go1.27.0.src.tar.gz", "go1.27.0 (hand-authored)"),
    hand(249, "tailscale", "tailscale-v1.102.3.tar.gz", "tailscale-1.102.3 (hand-authored)"),
    hand(250, "openbao", "openbao-v2.6.2.tar.gz", "openbao-2.6.2 (hand-authored)"),
    hand(251, "opentofu", "opentofu-v1.12.6.tar.gz", "opentofu-1.12.6 (hand-authored)"),
    hand(252, "rsync", "rsync-3.4.1.tar.gz", "rsync-3.4.1"),
]
