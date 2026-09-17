# SPDX-License-Identifier: MIT
# agent-built-lfs -- BLFS build plan for `server`
# Copyright (c) 2026 John Wassilak

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

from base import BASE, book, hand, slfs, glfs

PACKAGES = BASE + [
    # --- Hyprland desktop stack, HYPRLAND-PLAN.md, Tier 1-2 (2026-08-25) -----------
    # Policy from here: install each package's own BLFS "Recommended" deps (not just
    # Required) where they're plausible for this box -- but ONE level, not a chase
    # down every recommended dep's own recommended deps forever. Concretely: cmake's
    # Recommended (curl/libarchive/libuv/nghttp2, for its network-fetch/archive
    # features) and glib2's Recommended (docutils/libxslt, for docs/an xslt binding)
    # are skipped -- neither affects anything Hyprland/Firefox/mpv/ffmpeg actually
    # use cmake or glib2 for. Documented per-package below where it matters more.
    book(17, "cmake", "general/cmake.html", "cmake-4.4.2.tar.gz"),
    book(19, "brotli", "general/brotli.html", "brotli-1.2.0.tar.gz"),
    book(20, "highway", "general/highway.html", "highway-1.4.0.tar.gz"),
    book(21, "graphite2", "general/graphite2.html", "graphite2-1.3.14.tgz"),
    book(22, "giflib", "general/giflib.html", "giflib-6.1.3.tar.gz"),
    book(23, "libpng", "general/libpng.html", "libpng-1.6.58.tar.xz"),
    book(24, "lcms2", "general/lcms2.html", "lcms2-2.19.1.tar.gz"),

    # libjxl: Required deps only (brotli, cmake, giflib, highway, lcms2,
    # libjpeg-turbo[Arch, added separately], libpng) -- all built above.
    book(25, "libjxl", "general/libjxl.html", "libjxl-0.12.0.tar.gz"),

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
    book(28, "freetype2", "general/freetype2.html", "freetype-2.14.3.tar.xz"),
    book(29, "glib2", "general/glib2.html", "glib-2.88.3.tar.xz"),
    book(30, "icu", "general/icu.html", "icu4c-78.3-sources.tgz"),
    book(31, "harfbuzz", "general/harfbuzz.html", "harfbuzz-14.3.1.tar.xz"),
    book(32, "fontconfig", "general/fontconfig.html", "fontconfig-2.18.3.tar.xz"),
    book(33, "hwdata", "general/hwdata.html", "hwdata-0.410.tar.gz"),
    book(35, "nettle", "postlfs/nettle.html", "nettle-4.0.tar.gz"),
    book(36, "libtirpc", "basicnet/libtirpc.html", "libtirpc-1.3.7.tar.bz2"),

    # --- Tier 3 prep: X11/XCB compat, pulled ahead of HYPRLAND-PLAN.md's Tier 5
    # because libxkbcommon (Tier 3) recommends libxcb, and the whole chain needs
    # $XORG_PREFIX/$XORG_CONFIG from x/xorg7.html -- see blfs-xorg-env immediately below.
    #
    # x/xorg7.html: every Xorg/XCB-family BLFS recipe from here on (util-macros,
    # xorgproto, libXau, libXdmcp, xcb-proto, libxcb, libxcvt, xcb-util, and later xorg-
    # xwayland) uses $XORG_PREFIX and $XORG_CONFIG in its literal build commands -- the
    # book has the reader export them once, persist them via /etc/profile.d, and reuse
    # throughout. No page-specific command block captures this since it is shared setup,
    # not part of any one package's page.
    #
    # Fractional seq (36.5, between libtirpc=36 and util-macros=37), not the seq 120 this
    # was originally given: moved 2026-09-08, found rebuilding this host from scratch for
    # LFS 13.1. At seq 120 this ran fine on the live system (built incrementally, native
    # mode, whenever the operator happened to reach it -- order across chapters never
    # mattered there), but seq 120 is *after* every Xorg-family package that actually
    # needs $XORG_PREFIX, so a genuine fresh chroot build reaches xorgproto (seq 38)
    # before this step has ever run: meson sees an empty $XORG_PREFIX and hard-errors
    # ("prefix value '' must be an absolute path"). This comment already said "see
    # blfs-xorg-env below" right here, immediately above util-macros -- that was always
    # the intended position; seq 120 was the actual mistake. Not reusing 120 for anything
    # else, per CLAUDE.md's seq-permanence rule -- it is now a gap, real history.
    hand(36.5, "xorg-env", "", "xorg-env (hand-authored)"),
    book(37, "util-macros", "x/util-macros.html", "util-macros-1.20.2.tar.xz"),
    book(38, "xorgproto", "x/xorgproto.html", "xorgproto-2025.1.tar.xz"),
    book(39, "libXau", "x/libXau.html", "libXau-1.0.12.tar.xz"),
    book(40, "libXdmcp", "x/libXdmcp.html", "libXdmcp-1.1.5.tar.xz"),
    book(41, "xcb-proto", "x/xcb-proto.html", "xcb-proto-1.17.0.tar.xz"),
    book(42, "libxcb", "x/libxcb.html", "libxcb-1.17.0.tar.xz"),
    book(43, "libxcvt", "x/libxcvt.html", "libxcvt-0.1.3.tar.xz"),
    book(44, "xcb-util", "x/xcb-util.html", "xcb-util-0.4.1.tar.xz"),

    # --- Tier 3: Wayland core ---
    book(45, "libxml2", "general/libxml2.html", "libxml2-2.15.3.tar.xz"),
    book(48, "xkeyboard-config", "x/xkeyboard-config.html", "xkeyboard-config-2.48.tar.xz"),
    book(49, "libxkbcommon", "general/libxkbcommon.html", "libxkbcommon-1.13.2.tar.gz"),

    # Fractional seqs (49.1-49.7), not these packages' original seqs (124-170): moved
    # 2026-09-08, same fresh-chroot-build class of bug as blfs-xorg-env above. All seven
    # ran fine at their original positions on the live system (built incrementally,
    # native mode, long after vulkan-loader/mesa already existed there) but a genuine
    # fresh build reaches vulkan-loader (seq 54) and mesa (seq 56) before any of them
    # have run. vulkan-loader's cmake configure failed with 'required packages were not
    # found: x11' (needs xtrans, libx11, libxext, libxrender, libxrandr -- libxrandr's
    # own configure in turn needs the other three, all sequenced first here for that
    # reason); mesa's meson configure separately failed with 'Dependency xshmfence not
    # found' and 'Dependency xxf86vm not found'. Not reusing 124-126/132/168-170 for
    # anything else, per CLAUDE.md's seq-permanence rule -- they are now gaps, real
    # history, like the Hyprland-tier gaps HYPRLAND-PLAN.md already documents.
    hand(49.1, "xtrans", "xtrans-1.6.0.tar.xz", "xtrans (hand-authored)"),
    hand(49.2, "libx11", "libX11-1.8.13.tar.xz", "libx11 (hand-authored)"),
    hand(49.3, "libxext", "libXext-1.3.7.tar.xz", "libxext (hand-authored)"),
    hand(49.4, "libxrender", "libXrender-0.9.12.tar.xz", "libxrender (hand-authored)"),
    hand(49.5, "libxrandr", "libXrandr-1.5.5.tar.xz", "libxrandr (hand-authored)"),
    hand(49.6, "libxshmfence", "libxshmfence-1.3.3.tar.xz", "libxshmfence (hand-authored)"),
    hand(49.7, "libxxf86vm", "libXxf86vm-1.1.7.tar.xz", "libxxf86vm (hand-authored)"),

    # Fractional seq (49.8, not its original 127): moved 2026-09-08, same fresh-build
    # ordering bug as the cluster immediately above. mesa's meson configure (seq 56)
    # failed with 'Dependency "libglvnd" not found' -- mesa's x11 platform links against
    # it directly, not just a Recommended-by-mesa relationship the book documents
    # elsewhere. libglvnd's own Recommended dep (Xorg Libraries) is satisfied by the
    # xtrans/libx11/libxext/libxrender/libxrandr cluster just above. Not reusing 127 for
    # anything else, per CLAUDE.md's seq-permanence rule.
    glfs(49.8, "libglvnd", "core/libglvnd.html", "libglvnd-v1.7.0.tar.gz"),

    # --- Tier 4: GPU/GL stack. Driver scope decided with the operator: only this
    # box's actual hardware (GTX 770, Kepler) plus a software fallback -- nouveau +
    # llvmpipe gallium drivers, swrast for Vulkan (no NVK/nouveau Vulkan: doubtful
    # Kepler support, and it would need rust-bindgen on top of everything else).
    # Not the book's own "auto" (all drivers, all vendors) default.
    book(50, "spirv-headers", "general/spirv-headers.html", "SPIRV-Headers-vulkan-sdk-1.4.357.0.tar.gz"),
    book(51, "spirv-tools", "general/spirv-tools.html", "SPIRV-Tools-vulkan-sdk-1.4.357.0.tar.gz"),
    book(52, "glslang", "x/glslang.html", "glslang-16.5.0.tar.gz"),
    book(53, "vulkan-headers", "x/vulkan-headers.html", "Vulkan-Headers-vulkan-sdk-1.4.357.0.tar.gz"),
    book(54, "vulkan-loader", "x/vulkan-loader.html", "Vulkan-Loader-vulkan-sdk-1.4.357.0.tar.gz"),
    book(55, "libdrm", "x/libdrm.html", "libdrm-2.4.134.tar.xz"),

    # Fractional seqs (55.1-55.2), not their original 58-59: moved 2026-09-08, same
    # fresh-build ordering bug as the two clusters above. mesa's meson configure (next,
    # seq 56) failed with 'Unknown compiler(s): [['rustc']]' -- the host override above
    # (blfs-overrides.json) sets vulkan-drivers=nouveau for real NVK support (a decision
    # made 2026-08-26, after the stale "no NVK, doubtful Kepler support" comment a few
    # lines up was written), and Mesa 26.x's NVK driver compiles its NAK shader
    # translator, written in Rust, as a native meson subproject -- rustc is now a hard
    # requirement for that driver choice, not optional. libssh2 stays immediately before
    # rust, matching its position as rust's own Recommended dep (cargo's network-fetch
    # support) under this project's one-level Recommended-deps policy. Not reusing 58-59
    # for anything else, per CLAUDE.md's seq-permanence rule.
    book(55.1, "libssh2", "general/libssh2.html", "libssh2-1.11.1.tar.gz"),
    book(55.2, "rust", "general/rust.html", "rustc-1.97.1-src.tar.xz"),

    # Fractional seqs (55.3-55.5), not llvm's original 191 / cbindgen's original 61: moved
    # 2026-09-08, same fresh-build ordering bug, this time straight from mesa's own book
    # page rather than a discovered transitive failure -- x/mesa.html's Recommended list
    # names 'Cbindgen-0.29.4, make-ca-1.16.1, and rust-bindgen-0.72.1 (required for the
    # Nouveau Vulkan driver)' outright. rust-bindgen itself needs a real LLVM+Clang
    # (runtime libclang, for parsing C headers) -- the Tier 6 comment below explains why
    # this project normally avoids building LLVM at all (Rust links its own bundled
    # copy); llvm's own hand-authored recipe was written for Firefox, which still runs
    # fine from this earlier position (see recipes/blfs-llvm.sh's header, now stale about
    # being Firefox-only). rust-bindgen is a new package entry, not previously tracked in
    # packages.py at all: on the live system it must have been installed ad hoc (via
    # cargo install or similar) outside the tracked build, the same class of gap
    # ch08-perl's undocumented fix and the nvidia recipe's assumed kbuild tree were.
    hand(55.3, "llvm", "llvm-21.1.8.src.tar.xz", "LLVM-21.1.8 with clang (hand-authored)"),
    book(55.4, "rust-bindgen", "general/rust-bindgen.html", "rust-bindgen-0.72.1.tar.gz"),
    # Downgraded to hand() 2026-09-09, pinned to cbindgen-0.29.2 (not the book's
    # documented 0.29.4): Firefox's build (seq 192, invokes system cbindgen directly)
    # failed a real build against 0.29.4 -- see hosts/server/recipes/blfs-cbindgen.sh's
    # own header for the full "COUNT identifier" cbindgen-version-regression story and
    # why laptop's already-working 0.29.2 is the proven fix. mesa (seq 56, built earlier
    # in this same run against 0.29.4) is unaffected: cbindgen is a build-time-only tool,
    # not a runtime link dependency, so its already-built artifacts don't care which
    # version generated their headers.
    hand(55.5, "cbindgen", "cbindgen-0.29.2.tar.gz", "cbindgen-0.29.2 (hand-authored, version-pinned)"),

    # Fractional seqs (55.6-55.7), not pyyaml's original 123 -- same fresh-build ordering
    # bug, discovered the same way: mesa's meson.build (general/mesa.html's own Required
    # list names 'Mako-1.4.1... and PyYAML-6.0.3' outright) probes a list of python3.x
    # binaries and, for each, checks whether the mako and pyyaml modules import
    # successfully; none did (neither was installed yet at this earlier point in a fresh
    # build), so meson fell through the whole candidate list and errored 'Python >= 3.10
    # not found' -- a misleading message; the real gap is the two modules, not the
    # interpreter. mako itself was a second, standalone gap: recipes/blfs-mako.sh has
    # existed since this box's original Hyprland-tier work (its own header already says
    # "Required by Mesa's build-time code generation scripts") but was never actually
    # wired into this PACKAGES list -- a real oversight, not a version/ordering issue,
    # caught only because this fresh build is the first time anything has ever tried to
    # run recipes/blfs-mako.sh at all.
    hand(55.6, "mako", "mako-1.4.1.tar.gz", "Mako-1.4.1 (hand-authored)"),
    hand(55.7, "pyyaml", "pyyaml-6.0.3.tar.gz", "pyyaml (hand-authored)"),

    # Fractional seqs (55.8-55.9), not their original 214-215: same fresh-build ordering
    # bug, one more layer of it. mesa's meson.build auto-detects LLVM+Clang (now present,
    # moved above) and auto-enables its SPIR-V/OpenCL code path on that basis, which hard-
    # requires LLVMSPIRVLib (SPIRV-LLVM-Translator) at configure time -- confirmed via a
    # real failure ('Dependency "LLVMSPIRVLib" not found'). libclc moved alongside it
    # since it depends on spirv-llvm-translator and was already positioned immediately
    # after it in the file (214/215, both right after mesa's original 56) -- the same
    # "added out of order during incremental live-system work" pattern as llvm/rust-
    # bindgen/cbindgen/mako above. vulkan-tools (still seq 216, not moved) is not part of
    # this chain -- it is a standalone diagnostics package against vulkan-loader/vulkan-
    # headers, both already built well before this point.
    hand(55.8, "spirv-llvm-translator", "SPIRV-LLVM-Translator-21.1.4.tar.gz", "SPIRV-LLVM-Translator-21.1.4"),
    hand(55.9, "libclc", "libclc-21.1.8.src.tar.xz", "libclc-21.1.8"),

    # New package (not a moved one): mesa's host override above deliberately keeps the
    # book's platforms=x11,wayland default (see that override's own reason -- dropping it
    # would force a Mesa rebuild for no gain, since this box has abandoned Wayland, see
    # AWESOME-X11-PLAN.md). That reasoning assumed wayland-protocols was already
    # satisfied, but it was never actually built anywhere in this project -- a real gap,
    # only surfacing now because meson's pkg-config probe for it failed on a fresh build
    # and fell through to auto-downloading a fallback wrap subproject over the network,
    # which then failed too (this chroot has no working resolv.conf by default, same
    # class of issue as the cargo/npm/go fixes elsewhere in this file). Building the real
    # thing from its own BLFS page is the fix, not another network-fetch workaround: it is
    # a small, fast, no-compile package (protocol XML + meson install only), and this
    # project stages real sources rather than relying on a build tool's own live fetch
    # wherever a staged alternative exists.
    # wayland-protocols' own Required dep -- also never built anywhere in this project
    # despite the "Tier 3: Wayland core" header a few lines up (planned for the abandoned
    # Hyprland tier, never followed through once the pivot to X11 happened). Only
    # provides wayland-scanner and libwayland-client/-server here -- nothing on this box
    # runs an actual Wayland compositor or client, but mesa's kept platforms=x11,wayland
    # meson option still needs the scanner/headers to build its wayland-EGL platform
    # code, confirmed via a real failure ('Subprojectwayland is buildable: NO').
    book(55.93, "wayland", "general/wayland.html", "wayland-1.26.0.tar.xz"),
    book(55.95, "wayland-protocols", "general/wayland-protocols.html", "wayland-protocols-1.49.tar.xz"),

    book(56, "mesa", "x/mesa.html", "mesa-26.1.7.tar.xz"),
    book(57, "libepoxy", "x/libepoxy.html", "libepoxy-1.5.10.tar.xz"),

    # --- Tier 6: Cairo/Pango.
    book(60, "cargo-c", "general/cargo-c.html", "cargo-c-0.10.24.tar.gz"),
    book(62, "cairo", "x/cairo.html", "cairo-1.18.4.tar.xz"),

    # fribidi: pango's book page lists it as Required (Fontconfig, FriBidi-1.0.16,
    # GLib) -- missed adding it originally; discovered via a real pango meson failure.
    book(63, "fribidi", "general/fribidi.html", "fribidi-1.0.16.tar.xz"),
    book(64, "pango", "x/pango.html", "pango-1.58.2.tar.xz"),

    # gdk-pixbuf: librsvg's book page lists it only as Recommended, but librsvg's
    # own rsvg-pixbuf.h header hard #includes gdk-pixbuf/gdk-pixbuf.h -- the build
    # fails outright without it, discovered via a real librsvg meson/cc failure.
    # shared-mime-info is gdk-pixbuf's own Required dep, no deps beyond what's built.
    # Skipped gdk-pixbuf's other Recommended dep, glycin: circular (book says build
    # gdk-pixbuf without it first, then glycin, then rebuild gdk-pixbuf again) and a
    # heavy separate Rust image-loader stack -- out of scope for a one-level policy.
    book(65, "shared-mime-info", "general/shared-mime-info.html", "shared-mime-info-2.5.1.tar.gz"),

    # Fractional seq (65.5), not its original 68: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. gdk-pixbuf's own meson.build hard-requires
    # libjpeg (confirmed via a real failure: "Dependency 'libjpeg' is required but not
    # found") -- not documented in gdk-pixbuf's own BLFS Required/Recommended list at all,
    # only discoverable this way. libjpeg-turbo was already known to be needed somewhere
    # in this build (see the comment that used to sit here, now moved down with
    # muparser) but had never been checked against gdk-pixbuf specifically since the live
    # system built everything incrementally, out of file order.
    book(65.5, "libjpeg-turbo", "general/libjpeg.html", "libjpeg-turbo-3.2.0.tar.gz"),

    book(66, "gdk-pixbuf", "x/gdk-pixbuf.html", "gdk-pixbuf-2.44.7.tar.xz"),
    book(67, "librsvg", "general/librsvg.html", "librsvg-2.62.3.tar.xz"),

    # muparser: claimed "already built" in the Tier 10 hyprgraphics/hyprland rationale
    # comments below but never actually added to this list -- caught only by checking
    # for its manifest before staging Tier 10, same class of oversight as fribidi
    # earlier. Has a real BLFS page.
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
    book(71, "json-c", "general/json-c.html", "json-c-0.19.tar.gz"),
    book(72, "popt", "general/popt.html", "popt-1.19.tar.gz"),
    book(73, "lvm2", "postlfs/lvm2.html", "LVM2.2.03.42.tgz"),
    book(74, "cryptsetup", "postlfs/cryptsetup.html", "cryptsetup-2.8.7.tar.xz"),

    # --- Requested 2026-08-26: pass (the standard Unix password manager). Not in
    # BLFS itself; its own dependency chain (GnuPG + everything under it) is,
    # though -- pass just needs bash (have), gnupg, and tree at runtime.
    book(75, "libgpg-error", "general/libgpg-error.html", "libgpg-error-1.61.tar.bz2"),
    book(76, "libgcrypt", "general/libgcrypt.html", "libgcrypt-1.12.2.tar.bz2"),
    book(77, "libassuan", "general/libassuan.html", "libassuan-3.0.2.tar.bz2"),
    book(78, "libksba", "general/libksba.html", "libksba-1.8.0.tar.bz2"),
    book(79, "npth", "general/npth.html", "npth-1.8.tar.bz2"),
    book(80, "openldap", "server/openldap.html", "openldap-2.7.0.tgz"),
    book(81, "pinentry", "general/pinentry.html", "pinentry-1.3.3.tar.bz2"),
    book(82, "gnupg", "postlfs/gnupg.html", "gnupg-2.5.21.tar.bz2"),
    book(83, "tree", "general/tree.html", "unix-tree-2.3.2.tar.bz2"),

    # --- Tier 8: input & session management ---
    book(84, "libgudev", "general/libgudev.html", "libgudev-238.tar.xz"),
    book(85, "mtdev", "general/mtdev.html", "mtdev-1.1.7.tar.bz2"),

    # Fractional seq (85.5), not its original 128: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. libwacom's meson.build hard-requires
    # libevdev (confirmed via a real failure: "Dependency 'libevdev' not found") --
    # not documented on libwacom's own BLFS page (which doesn't exist; this package's
    # rationale below was written for libinput's sake, not knowing libwacom needed it
    # too until this fresh build actually hit the gap).
    hand(85.5, "libevdev", "libevdev-1.13.7.tar.xz", "libevdev (hand-authored)"),

    book(86, "libwacom", "general/libwacom.html", "libwacom-2.19.1.tar.xz"),

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
    book(95, "alsa-lib", "multimedia/alsa-lib.html", "alsa-lib-1.2.16.1.tar.bz2"),
    book(96, "speex", "multimedia/speex.html", "speex-1.2.1.tar.gz"),
    book(97, "gsettings-desktop-schemas", "gnome/gsettings-desktop-schemas.html", "gsettings-desktop-schemas-50.1.tar.xz"),

    # Fractional seqs (97.1-97.3), not their original 133/144/145: moved 2026-09-08, same
    # fresh-build ordering bug as elsewhere in this file. at-spi2-core's meson.build hard-
    # requires libxtst (confirmed via a real failure: "Dependency 'xtst' not found"),
    # which itself needs libxi, which itself needs libxfixes -- the whole chain sequenced
    # here in dependency order. libxcomposite/libxcursor (also needing libxfixes, still at
    # their original 134/135) are unrelated to this chain -- pure Hyprland deps, not
    # needed this early -- and are left in place.
    hand(97.1, "libxfixes", "libXfixes-6.0.2.tar.xz", "libxfixes (hand-authored)"),
    hand(97.2, "libxi", "libXi-1.8.3.tar.xz", "libxi (hand-authored)"),
    hand(97.3, "libxtst", "libXtst-1.2.5.tar.xz", "libxtst (hand-authored)"),

    book(98, "at-spi2-core", "x/at-spi2-core.html", "at-spi2-core-2.60.6.tar.xz"),
    book(99, "gtk3", "x/gtk3.html", "gtk-3.24.52.tar.xz"),

    # Fractional seqs (99.1-99.2), not their original 142-143: moved 2026-09-08, same
    # fresh-build ordering bug as elsewhere in this file. pulseaudio's meson.build hard-
    # requires libice and libsm (confirmed via a real failure: "Dependency 'ice' not
    # found"), sequenced here in dependency order (libsm needs libice).
    hand(99.1, "libice", "libICE-1.1.2.tar.xz", "libice (hand-authored)"),
    hand(99.2, "libsm", "libSM-1.2.6.tar.xz", "libsm (hand-authored)"),

    book(100, "pulseaudio", "multimedia/pulseaudio.html", "pulseaudio-17.0.tar.xz"),

    # --- Tier 12: media codecs for FFmpeg/mpv (2026-08-26). All real BLFS book
    # pages. NASM built first -- Recommended by nearly everything else here.
    # Scope: FFmpeg's own Recommended list (not its much longer Optional list)
    # plus mpv's Required/Recommended, per the one-level Recommended-deps policy.
    book(101, "nasm", "general/nasm.html", "nasm-3.02.tar.xz"),
    book(102, "libusb", "general/libusb.html", "libusb-1.0.30.tar.bz2"),
    book(103, "dav1d", "multimedia/dav1d.html", "dav1d-1.5.4.tar.gz"),
    book(104, "libaom", "multimedia/libaom.html", "libaom-3.14.1.tar.gz"),
    book(105, "libvpx", "multimedia/libvpx.html", "libvpx-1.16.0.tar.gz"),
    book(106, "x264", "multimedia/x264.html", "x264-20250815.tar.xz"),
    book(107, "x265", "multimedia/x265.html", "x265_4.2.tar.gz"),
    book(108, "lame", "multimedia/lame.html", "lame-3.100.tar.gz"),
    book(109, "libass", "multimedia/libass.html", "libass-0.17.5.tar.xz"),
    book(110, "svt-av1", "multimedia/svt-av1.html", "SVT-AV1-v4.2.0.tar.gz"),
    book(111, "fdk-aac", "multimedia/fdk-aac.html", "fdk-aac-2.0.3.tar.gz"),
    book(112, "libva", "multimedia/libva.html", "libva-2.24.1.tar.gz"),

    # Fractional seq (112.5), not its original 135: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. SDL3's cmake hard-requires it when X11
    # support is enabled (confirmed via a real failure: "Couldn't find dependency
    # package for XCURSOR") -- not documented on SDL3's own book page (which only lists
    # the generic Xorg Libraries as part of Recommended, same undocumented-transitive-
    # dependency pattern as libxscrnsaver a few lines up).
    hand(112.5, "libxcursor", "libXcursor-1.2.3.tar.xz", "libxcursor (hand-authored)"),

    # Fractional seq (112.6), not its original 141: moved 2026-09-08 alongside libxcursor
    # above, same reason (SDL3's cmake X11 checks). SDL3's other X11 extension checks
    # (XDBE, XSYNC, XSHAPE) are satisfied by libxext, already built; XINPUT/XFIXES/XRANDR/
    # XTEST by libxi/libxfixes/libxrandr/libxtst, all already built earlier too -- this
    # was the last one actually missing.
    hand(112.6, "libxscrnsaver", "libXScrnSaver-1.2.5.tar.xz", "libxscrnsaver (hand-authored)"),

    book(113, "sdl3", "multimedia/sdl3.html", "SDL3-3.4.14.tar.gz"),
    book(114, "sdl2-compat", "multimedia/sdl2.html", "sdl2-compat-2.32.70.tar.gz"),

    # --- Requested 2026-08-26: GNU Screen. Not part of the Hyprland/media-codec
    # stack -- queued as a quick standalone build. No hard deps (book's own
    # configure already passes --disable-pam, so the Optional Linux-PAM dep
    # doesn't apply).
    book(115, "screen", "general/screen.html", "screen-5.0.2.tar.gz"),

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

    # Not in BLFS. libei's book page lists it as Required ('Required attrs-25.4.0') -- a
    # pure-Python package, same pip3-wheel pattern as pyyaml/mako (built above, moved
    # 2026-09-08), except *without* --no-build-isolation: unlike pyyaml/mako (setuptools,
    # already present), attrs' build backend is hatchling, not installed -- discovered via
    # a real 'Cannot import hatchling.build' failure. Letting pip's normal isolated build
    # fetch hatchling itself (this target has direct internet access, confirmed by every
    # curl fetch this session) into a throwaway build venv is simpler and more honest than
    # hand-vendoring hatchling as its own recipe; the final `pip3 install` step of *this*
    # package still installs only the offline-built attrs wheel, no network involved.
    # Sourced from PyPI directly (files.pythonhosted.org), sha256 verified against PyPI's
    # own published digest for the 25.4.0 sdist.
    hand(122, "attrs", "attrs-25.4.0.tar.gz", "attrs (hand-authored)"),

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

    # Not in this BLFS mirror. Direct Hyprland dependency, needs libxfixes (built above,
    # seq 97.1, moved 2026-09-08 for at-spi2-core's sake).
    hand(134, "libxcomposite", "libXcomposite-0.4.7.tar.xz", "libxcomposite (hand-authored)"),

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

    # Moved 2026-09-07 from a hand-authored, Arch-PKGBUILD-referenced recipe to a real
    # SLFS 13.1 book page (general/htop.html), onboarded as this project's first SLFS
    # source -- SLFS/GLFS are now preferred over the Arch/AUR two-tier fallback wherever
    # one of them actually covers a package (see BUILD-REPORT.md, 2026-09-07). The SLFS
    # page's own recipe (./configure --prefix=/usr && make; make pixmapdir=... install)
    # is simpler than the superseded hand recipe -- no git clone, no --enable-sensors/
    # --enable-delayacct/--enable-capabilities/--enable-unicode flags at all, htop-3.5.3's
    # own configure defaults cover this build (confirmed by reading the page directly:
    # no admonition-flagged alternative blocks, nothing conditional). Installed htop is
    # unaffected -- this only changes what a future rebuild sources from.
    slfs(175, "htop", "general/htop.html", "htop-3.5.3.tar.xz"),

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

    # Fractional seq (177.1), not its original 119: moved 2026-09-08, same fresh-build
    # ordering bug as blfs-sudo (see adduser-john's own comment above): this recipe runs
    # `su - john -c '...'`, and needs john's account/home directory to already exist --
    # true on the live system (john already existed from long before seq 119 was ever
    # added there) but not on a fresh build, where seq 119 runs long before adduser-john
    # (177) ever creates the account. Confirmed via a real failure: "No passwd entry for
    # user 'john'". Needs working DNS inside the chroot, which the LFS resolv.conf
    # symlink cannot provide here (handled inside the recipe itself).
    hand(177.1, "claude-code", "", "claude-code (hand-authored)"),

    hand(178, "glad", "glad-2.0.8.tar.gz", "Glad-2.0.8 (hand-authored)"),
    hand(179, "libplacebo", "libplacebo-7.360.1.tar.gz", "libplacebo-7.360.0 (hand-authored)"),
    hand(179.5, "nv-codec-headers", "nv-codec-headers-11.1.5.3.tar.gz", "nv-codec-headers-11.1.5.3 (hand-authored, version-pinned to the 470.x driver)"),

    # Fractional seq (179.6), not its original 217: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. ffmpeg's configure hard-requires it once
    # --enable-vdpau is requested (confirmed via a real failure: "ERROR: vdpau requested
    # but not found"). vdpauinfo (still at its original seq 240, a runtime diagnostic
    # tool, not an ffmpeg build dependency) is left in place.
    hand(179.6, "libvdpau", "libvdpau-1.5.tar.gz", "libvdpau (hand-authored)"),

    hand(180, "ffmpeg", "ffmpeg-8.0.1.tar.xz", "FFmpeg-8.0.1 (hand-authored)"),
    hand(181, "luajit", "luajit-20260213.tar.xz", "luajit-20260213 (hand-authored)"),
    hand(182, "uchardet", "uchardet-0.0.8.tar.xz", "uchardet-0.0.8 (hand-authored)"),

    # Fractional seq (182.5), not its original 184: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. mpv's meson.build hard-requires it once
    # X11 support is enabled (confirmed via a real failure: "Dependency 'xpresent' not
    # found").
    hand(182.5, "libxpresent", "libXpresent-1.0.2.tar.xz", "libXpresent-1.0.2 (hand-authored)"),

    hand(183, "mpv", "mpv-0.41.0.tar.gz", "mpv-0.41.0 (hand-authored)"),
    hand(185, "nspr", "nspr-4.38.2.tar.gz", "NSPR-4.38.2 (hand-authored)"),
    hand(186, "nss", "nss-3.120.1.tar.gz", "NSS-3.120.1 (hand-authored)"),
    hand(187, "libarchive", "libarchive-3.8.5.tar.xz", "libarchive-3.8.5 (hand-authored)"),
    hand(188, "libnotify", "libnotify-0.8.8.tar.xz", "libnotify-0.8.8 (hand-authored)"),
    hand(189, "startup-notification", "startup-notification-0.12.tar.gz", "startup-notification-0.12 (hand-authored)"),
    hand(190, "libevent", "libevent-2.1.12-stable.tar.gz", "libevent-2.1.12 (hand-authored)"),

    # Fractional seq (190.5), not its original 241: moved 2026-09-08, same fresh-build
    # ordering bug as elsewhere in this file. Firefox's configure hard-requires it as
    # part of its combined X11 pkg-config probe (confirmed via a real failure: "Package
    # 'xdamage' not found" -- the other packages in that same probe, x11/xcb/xext/
    # xrandr/xcomposite/xcursor/xfixes/xi, were all already built earlier).
    hand(190.5, "libxdamage", "libXdamage-1.1.7.tar.xz", "libXdamage-1.1.7 (hand-authored)", page="x7lib"),

    hand(192, "firefox", "firefox-140.8.0esr.source.tar.xz", "Firefox-140.8.0esr (hand-authored)"),
    hand(193, "pciutils", "pciutils-3.14.0.tar.gz", "pciutils-3.14.0 (hand-authored)"),
    hand(194, "pipewire", "pipewire-1.6.0.tar.bz2", "pipewire-1.6.0 (hand-authored)"),
    hand(195, "wireplumber", "wireplumber-0.5.13.tar.bz2", "Wireplumber-0.5.13 (hand-authored)"),
    hand(196, "wireguard-tools", "wireguard-tools-1.0.20260223.tar.xz", "wireguard-tools-1.0.20260223 (hand-authored)"),
    hand(197, "xkbcomp", "xkbcomp-xkbcomp-1.5.0.tar.gz", "xkbcomp-1.5.0 (hand-authored)"),
    hand(198, "jq", "jq-1.8.2.tar.gz", "jq-1.8.2 (hand-authored)"),
    hand(204, "alacritty", "alacritty-0.17.0.tar.gz", "alacritty-0.17.0 (hand-authored)"),
    hand(206, "dejavu-fonts", "dejavu-fonts-ttf-2.37.tar.bz2", "DejaVu fonts 2.37 (hand-authored)", page="TTF-and-OTF-fonts"),
    # tarball repackaged 2026-09-09, .zip -> .tar.gz (matching laptop's own already-
    # working JetBrainsMono-2.304.tar.gz exactly): bin/lfsbuild's generic unpack logic
    # is tar-only (`tar -tf`/`tar -xf`), same class of gap as the NVIDIA .run installer
    # -- upstream only ships this as a .zip. Repackaged with the same top-level
    # JetBrainsMono-2.304/ wrapper this recipe's relative `fonts/ttf/*.ttf` path already
    # assumes, byte-identical contents otherwise (confirmed: same fonts/, AUTHORS.txt,
    # OFL.txt).
    hand(207, "jetbrains-mono-fonts", "JetBrainsMono-2.304.tar.gz", "JetBrains Mono 2.304 (hand-authored)", page="TTF-and-OTF-fonts"),
    hand(208, "hicolor-icon-theme", "hicolor-icon-theme-0.18.tar.xz", "hicolor-icon-theme-0.18"),
    hand(209, "usbutils", "usbutils-019.tar.xz", "usbutils-019"),
    hand(212, "libva-utils", "libva-utils-2.24.0.tar.gz", "libva-utils-2.24.0 (hand-authored)"),
    hand(216, "vulkan-tools", "Vulkan-Tools-1.4.341.tar.gz", "Vulkan-Tools-1.4.341 (hand-authored)"),
    # tarball="" (not the .run installer name): the recipe fetches the driver itself via
    # wget and the patch set via git clone, so there is nothing for the driver's generic
    # tar-based unpack to stage or extract -- a .run file is a self-extracting shell
    # script, not a tar archive, and `tar -tf`/`tar -xf` on it fails outright. Found
    # 2026-09-08 rebuilding this step for LFS 13.1: previously reconciled as complete
    # from manifest evidence on the live system, never actually driven through
    # lfsbuild's normal unpack path before.
    hand(218, "nvidia-470xx", "", "NVIDIA-Linux-x86_64-470.256.02 (hand-authored, experimental)"),
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

    # Operator-requested (2026-09-04): pass/pass-otp completions install correctly
    # (confirmed in their own manifests) but nothing sources them -- this framework
    # package was never built on either host. Not in BLFS (checked the book
    # directly, see recipes/blfs-bash-completion.sh's own header). Same shared
    # recipe as laptop (seq 246) -- portable, no host-specific content.
    hand(253, "bash-completion", "bash-completion-2.18.0.tar.xz",
         "bash-completion-2.18.0 (hand-authored, shared recipe)"),

    # Operator-requested (2026-09-17). The RCE data-engineering repos import pyodbc at
    # module scope, so with no libodbc.so.2 on this box every one of rce-etl's test
    # files dies at collection -- 38 collection errors, the whole suite, before a
    # single assertion runs. That repo's governance gate (tools/govern/check.sh under
    # ADR-0037) runs `uv run pytest` as its one behavioural check before a change
    # reaches a production container image, so on this machine that gate has been
    # reporting success without executing a test. Found while fixing RCE-651.
    #
    # Client library only. Nothing here talks to SQL Server directly: the foundation-db
    # tunnel SOP uses pymssql/FreeTDS, and the ETL containers carry their own
    # msodbcsql18 driver. This is purely so `import pyodbc` resolves and the tests can
    # be run and trusted. The book page's Optional dep (Mini SQL) is skipped -- it is a
    # driver for a database nothing in this estate uses.
    book(254, "unixodbc", "general/unixodbc.html", "unixODBC-2.3.14.tar.gz"),
]
