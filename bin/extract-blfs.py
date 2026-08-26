#!/usr/bin/env python3
"""Extract BLFS recipes for the minimal set needed to run Claude Code in the LFS system.

Reuses the LFS extractor's page parser and classifier, so BLFS packages get the same
treatment: candidate recipes from the book, review decisions persisted in
recipes/blfs-overrides.json, and per-package manifests from the driver.

Scope is deliberately tight -- the dependency closure of the four things asked for:

  DHCP     already provided by systemd-networkd from LFS; nothing to build.
  which    the ONLY hard requirement of Node.js.
  libtasn1 -> p11-kit -> make-ca   the CA certificate store. Without it npm and
           Claude Code cannot complete a single TLS handshake; /etc/ssl/certs is
           empty on a by-the-book LFS system.
  nodejs   provides npm. Built with its bundled brotli/c-ares/ICU/libuv/nghttp2,
           which BLFS lists only as "recommended" -- taking the bundled copies keeps
           the closure small and uses the versions upstream tests against.
  openssh  ssh and sshd. No required dependencies beyond LFS.
  curl/wget  not needed by Claude Code, but dependencies of a large share of BLFS,
           so worth having now. Closure: libunistring -> libidn2 -> libpsl.
  git      no new dependencies -- cURL (http/https remotes) and OpenSSH (ssh remotes)
           are both already present. Man pages come from the prebuilt tarball rather
           than building them, which would need asciidoc and xmlto.

Order below is dependency order and is what the plan preserves.
"""

import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BOOK = f"{ROOT}/book/blfs-13.0"
OUT = f"{ROOT}/recipes"
STATE = f"{ROOT}/state"
OVERRIDES = f"{OUT}/blfs-overrides.json"

# Reuse the LFS extractor rather than duplicating the parser.
_spec = importlib.util.spec_from_file_location("lfsx", f"{HERE}/extract-recipes.py")
lfsx = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lfsx)

class BlfsPageParser(lfsx.PageParser):
    """BLFS marks root-only commands with <pre class="root">, and that is where every
    `make install` lives. The LFS parser only captures class="userinput", which silently
    dropped the install step from every BLFS recipe. Capture both, in document order,
    and record which class each came from -- inside the chroot we are root either way."""

    def handle_starttag(self, tag, attrs):
        if tag == "pre":
            cls = dict(attrs).get("class", "")
            if "userinput" in cls or "root" in cls:
                self.in_pre = "userinput"
                self._src_class = cls
            else:
                self.in_pre = "screen"
            self.buf = []
            return
        super().handle_starttag(tag, attrs)


# (name, book page, source tarball, capture manifest)
PACKAGES = [
    ("which",    "general/which.html",     "which-2.23.tar.gz"),
    ("libtasn1", "general/libtasn1.html",  "libtasn1-4.21.0.tar.gz"),
    ("p11-kit",  "postlfs/p11-kit.html",   "p11-kit-0.26.2.tar.xz"),
    ("make-ca",  "postlfs/make-ca.html",   "make-ca-1.16.1.tar.gz"),
    ("openssh",  "postlfs/openssh.html",   "openssh-10.2p1.tar.gz"),
    ("nodejs",   "general/nodejs.html",    "node-v22.22.0.tar.xz"),
    # Added after the fact: curl and wget are required or recommended by a large
    # share of BLFS, so having them present saves repeated detours later. Their
    # closure is libunistring -> libidn2 -> libpsl. libpsl is not optional in
    # practice: BLFS notes that building curl without it has "severe security
    # implications" (it is what stops cookies being set across public suffixes).
    ("libunistring", "general/libunistring.html", "libunistring-1.4.1.tar.xz"),
    ("libidn2",      "general/libidn2.html",      "libidn2-2.3.8.tar.gz"),
    ("libpsl",       "basicnet/libpsl.html",      "libpsl-0.21.5.tar.gz"),
    ("curl",         "basicnet/curl.html",        "curl-8.18.0.tar.xz"),
    ("wget",         "basicnet/wget.html",        "wget-1.25.0.tar.gz"),
    # git: no new dependencies. Its one recommended dep is cURL (for http/https
    # remotes), and OpenSSH covers git-over-ssh -- both already installed above.
    ("git",          "general/git.html",          "git-2.53.0.tar.xz"),
    # Added post-deployment (2026-08-25 baseline hardware audit): cpio is a build
    # dependency for the hand-crafted microcode initrd (blfs-intel-microcode below),
    # not something Claude Code needs. No new dependencies of its own.
    ("cpio",         "general/cpio.html",         "cpio-2.15.tar.bz2"),
    # Added 2026-08-25: BLFS's general post-LFS setup, ahead of a first non-root user.
    # No tarball -- this is a configuration page, not a package build. Four blocks
    # (~/.bash_profile, ~/.profile, ~/.bashrc, ~/.bash_logout) get redirected to
    # /etc/skel via overrides, per the book's own suggested modification in skel.html.
    ("shell-startup-files", "postlfs/profile.html", ""),
    # Added 2026-08-25: standing policy from here on is to install BLFS's Recommended
    # dependencies by default, not just Required -- but check each one against what
    # this box actually is before pulling it in (see blfs-vim decision in the build
    # report: vim's only Recommended dep is a GTK3 desktop GUI, skipped as wrong for
    # a headless server, not blindly installed). sudo itself has no Recommended deps.
    ("sudo",         "postlfs/sudo.html",         "sudo-1.9.17p2.tar.gz"),
    # Requires the netfilter-legacy-enabled kernel (6.18.10-nftables) -- the running
    # kernel this system shipped with has neither NF_TABLES nor
    # NETFILTER_XTABLES_LEGACY, so a plain book build would produce a binary that
    # can't create the `filter` table at all. Kernel side is a separate rebuild
    # (kernel-config.sh), tracked in BUILD-REPORT.md, not this recipe.
    ("iptables",     "postlfs/iptables.html",     "iptables-1.8.12.tar.xz"),

    # --- Hyprland desktop stack, HYPRLAND-PLAN.md, Tier 1-2 (2026-08-25) -----------
    # Policy from here: install each package's own BLFS "Recommended" deps (not just
    # Required) where they're plausible for this box -- but ONE level, not a chase
    # down every recommended dep's own recommended deps forever. Concretely: cmake's
    # Recommended (curl/libarchive/libuv/nghttp2, for its network-fetch/archive
    # features) and glib2's Recommended (docutils/libxslt, for docs/an xslt binding)
    # are skipped -- neither affects anything Hyprland/Firefox/mpv/ffmpeg actually
    # use cmake or glib2 for. Documented per-package below where it matters more.
    ("cmake",        "general/cmake.html",        "cmake-4.2.3.tar.gz"),
    ("abseil-cpp",   "general/abseil-cpp.html",   "abseil-cpp-20260107.1.tar.gz"),
    ("brotli",       "general/brotli.html",       "brotli-1.2.0.tar.gz"),
    ("highway",      "general/highway.html",      "highway-1.3.0.tar.gz"),
    ("graphite2",    "general/graphite2.html",    "graphite2-1.3.14.tgz"),
    ("giflib",       "general/giflib.html",       "giflib-5.2.2.tar.gz"),
    ("libpng",       "general/libpng.html",       "libpng-1.6.55.tar.xz"),
    ("lcms2",        "general/lcms2.html",        "lcms2-2.18.tar.gz"),
    # libjxl: Required deps only (brotli, cmake, giflib, highway, lcms2,
    # libjpeg-turbo[Arch, added separately], libpng) -- all built above.
    ("libjxl",       "general/libjxl.html",       "libjxl-0.11.2.tar.gz"),
    # libwebp: Recommended is libjpeg-turbo/libpng (have) + libtiff/sdl2-compat "for
    # improved 3D acceleration" -- not built yet (sdl2-compat is tier 11, libtiff
    # not otherwise needed), skipped rather than reordering the whole plan for a
    # 3D-acceleration enhancement to a still-image codec.
    ("libwebp",      "general/libwebp.html",      "libwebp-1.6.0.tar.gz"),
    ("pixman",       "general/pixman.html",       "pixman-0.46.4.tar.gz"),
    # freetype2: Recommended harfbuzz is circular (harfbuzz also recommends
    # freetype2) -- book's own bootstrap order is freetype2 first without it, which
    # is what this does; harfbuzz follows below and links against this freetype2.
    # which-2.23 already built (original Claude Code dependency chain).
    ("freetype2",    "general/freetype2.html",    "freetype-2.14.1.tar.xz"),
    ("glib2",        "general/glib2.html",        "glib-2.86.4.tar.xz"),
    ("icu",          "general/icu.html",          "icu4c-78.2-sources.tgz"),
    ("harfbuzz",     "general/harfbuzz.html",     "harfbuzz-12.3.2.tar.xz"),
    ("fontconfig",   "general/fontconfig.html",   "fontconfig-2.17.1.tar.xz"),
    ("hwdata",       "general/hwdata.html",       "hwdata-0.404.tar.gz"),
    ("libdisplay-info", "general/libdisplay-info.html", "libdisplay-info-0.3.0.tar.xz"),
    ("nettle",       "postlfs/nettle.html",       "nettle-3.10.2.tar.gz"),
    ("libtirpc",     "basicnet/libtirpc.html",    "libtirpc-1.3.7.tar.bz2"),

    # --- Tier 3 prep: X11/XCB compat, pulled ahead of HYPRLAND-PLAN.md's Tier 5
    # because libxkbcommon (Tier 3) recommends libxcb, and the whole chain needs
    # $XORG_PREFIX/$XORG_CONFIG from x/xorg7.html -- see blfs-xorg-env below.
    ("util-macros",  "x/util-macros.html",        "util-macros-1.20.2.tar.xz"),
    ("xorgproto",    "x/xorgproto.html",          "xorgproto-2025.1.tar.xz"),
    ("libXau",       "x/libXau.html",             "libXau-1.0.12.tar.xz"),
    ("libXdmcp",     "x/libXdmcp.html",           "libXdmcp-1.1.5.tar.xz"),
    ("xcb-proto",    "x/xcb-proto.html",          "xcb-proto-1.17.0.tar.xz"),
    ("libxcb",       "x/libxcb.html",             "libxcb-1.17.0.tar.xz"),
    ("libxcvt",      "x/libxcvt.html",            "libxcvt-0.1.3.tar.xz"),
    ("xcb-util",     "x/xcb-util.html",           "xcb-util-0.4.1.tar.xz"),

    # --- Tier 3: Wayland core ---
    ("libxml2",      "general/libxml2.html",      "libxml2-2.15.1.tar.xz"),
    # 1.26.0, not the book-pinned 1.24.0: cascaded from the wayland-protocols
    # bump below -- wayland-protocols 1.49 itself requires wayland-scanner
    # >=1.25.0, discovered via a real meson configure failure. Same generic
    # meson build works unmodified against the newer tarball.
    ("wayland",      "general/wayland.html",      "wayland-1.26.0.tar.xz"),
    # 1.49, not the book-pinned 1.47: Hyprland's own CMakeLists hard-requires
    # wayland-protocols>=1.49, discovered via a real configure failure. Same
    # generic meson build works unmodified against the newer tarball.
    ("wayland-protocols", "general/wayland-protocols.html", "wayland-protocols-1.49.tar.xz"),
    ("xkeyboard-config",  "x/xkeyboard-config.html", "xkeyboard-config-2.46.tar.xz"),
    ("libxkbcommon", "general/libxkbcommon.html", "libxkbcommon-1.13.1.tar.gz"),

    # --- Tier 4: GPU/GL stack. Driver scope decided with the operator: only this
    # box's actual hardware (GTX 770, Kepler) plus a software fallback -- nouveau +
    # llvmpipe gallium drivers, swrast for Vulkan (no NVK/nouveau Vulkan: doubtful
    # Kepler support, and it would need rust-bindgen on top of everything else).
    # Not the book's own "auto" (all drivers, all vendors) default.
    ("spirv-headers", "general/spirv-headers.html", "SPIRV-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    ("spirv-tools",  "general/spirv-tools.html",   "SPIRV-Tools-vulkan-sdk-1.4.341.0.tar.gz"),
    ("glslang",      "x/glslang.html",             "glslang-16.2.0.tar.gz"),
    ("vulkan-headers", "x/vulkan-headers.html",    "Vulkan-Headers-vulkan-sdk-1.4.341.0.tar.gz"),
    ("vulkan-loader", "x/vulkan-loader.html",      "Vulkan-Loader-vulkan-sdk-1.4.341.0.tar.gz"),
    ("libdrm",       "x/libdrm.html",              "libdrm-2.4.131.tar.xz"),
    ("mesa",         "x/mesa.html",                "mesa-25.3.5.tar.xz"),
    ("libepoxy",     "x/libepoxy.html",            "libepoxy-1.5.10.tar.xz"),

    # --- Tier 6: Rust toolchain + Cairo/Pango. Decided with the operator to skip
    # building LLVM as its own package (4.7GB, 3 extra tarballs, hours) even though
    # Rust's bootstrap.toml recommends linking system LLVM -- Rust falls back to
    # its own bundled copy (book's own words: "the resulting build will be larger
    # and take longer", but avoids a second, separately-massive LLVM build on top).
    ("libssh2",      "general/libssh2.html",       "libssh2-1.11.1.tar.gz"),
    ("rust",         "general/rust.html",          "rustc-1.93.1-src.tar.xz"),
    ("cargo-c",      "general/cargo-c.html",       "cargo-c-0.10.20.tar.gz"),
    ("cbindgen",     "general/cbindgen.html",      "cbindgen-0.29.2.tar.gz"),
    ("cairo",        "x/cairo.html",               "cairo-1.18.4.tar.xz"),
    # fribidi: pango's book page lists it as Required (Fontconfig, FriBidi-1.0.16,
    # GLib) -- missed adding it originally; discovered via a real pango meson failure.
    ("fribidi",      "general/fribidi.html",       "fribidi-1.0.16.tar.xz"),
    ("pango",        "x/pango.html",               "pango-1.57.0.tar.xz"),
    # gdk-pixbuf: librsvg's book page lists it only as Recommended, but librsvg's
    # own rsvg-pixbuf.h header hard #includes gdk-pixbuf/gdk-pixbuf.h -- the build
    # fails outright without it, discovered via a real librsvg meson/cc failure.
    # shared-mime-info is gdk-pixbuf's own Required dep, no deps beyond what's built.
    # Skipped gdk-pixbuf's other Recommended dep, glycin: circular (book says build
    # gdk-pixbuf without it first, then glycin, then rebuild gdk-pixbuf again) and a
    # heavy separate Rust image-loader stack -- out of scope for a one-level policy.
    ("shared-mime-info", "general/shared-mime-info.html", "shared-mime-info-2.4.tar.gz"),
    ("gdk-pixbuf",    "x/gdk-pixbuf.html",          "gdk-pixbuf-2.44.5.tar.xz"),
    ("librsvg",      "general/librsvg.html",       "librsvg-2.61.4.tar.xz"),

    # libjpeg-turbo and muparser: both claimed "already built" in the Tier 10
    # hyprgraphics/hyprland rationale comments below but never actually added to
    # this list -- caught only by checking for their manifests before staging Tier
    # 10, same class of oversight as fribidi earlier. Both have real BLFS pages.
    ("libjpeg-turbo", "general/libjpeg.html",       "libjpeg-turbo-3.1.3.tar.gz"),
    ("muparser",      "lxqt/muparser.html",         "muparser-2.3.5.tar.gz"),

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
    ("libaio",       "general/libaio.html",        "libaio-0.3.113.tar.gz"),
    ("json-c",       "general/json-c.html",        "json-c-0.18.tar.gz"),
    ("popt",         "general/popt.html",          "popt-1.19.tar.gz"),
    ("lvm2",         "postlfs/lvm2.html",          "LVM2.2.03.38.tgz"),
    ("cryptsetup",   "postlfs/cryptsetup.html",    "cryptsetup-2.8.4.tar.xz"),

    # --- Requested 2026-08-26: pass (the standard Unix password manager). Not in
    # BLFS itself; its own dependency chain (GnuPG + everything under it) is,
    # though -- pass just needs bash (have), gnupg, and tree at runtime.
    ("libgpg-error", "general/libgpg-error.html",  "libgpg-error-1.59.tar.bz2"),
    ("libgcrypt",    "general/libgcrypt.html",     "libgcrypt-1.12.0.tar.bz2"),
    ("libassuan",    "general/libassuan.html",     "libassuan-3.0.2.tar.bz2"),
    ("libksba",      "general/libksba.html",       "libksba-1.6.7.tar.bz2"),
    ("npth",         "general/npth.html",          "npth-1.8.tar.bz2"),
    ("openldap",     "server/openldap.html",       "openldap-2.6.12.tgz"),
    ("pinentry",     "general/pinentry.html",      "pinentry-1.3.2.tar.bz2"),
    ("gnupg",        "postlfs/gnupg.html",         "gnupg-2.5.17.tar.bz2"),
    ("tree",         "general/tree.html",          "unix-tree-2.3.1.tar.bz2"),

    # --- Tier 8: input & session management ---
    ("libgudev",     "general/libgudev.html",      "libgudev-238.tar.xz"),
    ("mtdev",        "general/mtdev.html",         "mtdev-1.1.7.tar.bz2"),
    ("libwacom",     "general/libwacom.html",      "libwacom-2.18.0.tar.xz"),

    # --- Tier 9: XWayland. BLFS's own xwayland.html dependency list is much
    # leaner than Arch's equivalent package (which builds more optional
    # features) -- Required: libxcvt/pixman/wayland-protocols (have) + font-util;
    # Recommended: libepoxy/libtirpc/mesa (have). No libxfont2, libdecor, or the
    # rest of the legacy X11 lib set Arch's build pulls in but this one doesn't.
    ("dbus",         "general/dbus.html",          "dbus-1.16.2.tar.xz"),
    ("libei",        "x/libei.html",               "libei-1.5.0.tar.xz"),
    ("xwayland",     "x/xwayland.html",            "xwayland-24.1.9.tar.xz"),

    # --- Tier 11: GTK3 + PulseAudio prerequisites (2026-08-26). All real BLFS
    # book pages. Chain: libogg -> flac/libvorbis/speex (Recommended/Required
    # deps of libsndfile and pulseaudio) -> libsndfile; gsettings-desktop-schemas
    # -> at-spi2-core -> gtk3; alsa-lib and speex Recommended by pulseaudio too.
    ("libogg",       "multimedia/libogg.html",     "libogg-1.3.6.tar.xz"),
    ("flac",         "multimedia/flac.html",       "flac-1.5.0.tar.xz"),
    ("opus",         "multimedia/opus.html",       "opus-1.6.1.tar.gz"),
    ("libvorbis",    "multimedia/libvorbis.html",  "libvorbis-1.3.7.tar.xz"),
    ("libsndfile",   "multimedia/libsndfile.html", "libsndfile-1.2.2.tar.xz"),
    ("alsa-lib",     "multimedia/alsa-lib.html",   "alsa-lib-1.2.15.3.tar.bz2"),
    ("speex",        "multimedia/speex.html",      "speex-1.2.1.tar.gz"),
    ("gsettings-desktop-schemas", "gnome/gsettings-desktop-schemas.html",
                                                    "gsettings-desktop-schemas-49.1.tar.xz"),
    ("at-spi2-core",  "x/at-spi2-core.html",       "at-spi2-core-2.58.3.tar.xz"),
    ("gtk3",          "x/gtk3.html",               "gtk-3.24.51.tar.xz"),
    ("pulseaudio",    "multimedia/pulseaudio.html", "pulseaudio-17.0.tar.xz"),

    # --- Tier 12: media codecs for FFmpeg/mpv (2026-08-26). All real BLFS book
    # pages. NASM built first -- Recommended by nearly everything else here.
    # Scope: FFmpeg's own Recommended list (not its much longer Optional list)
    # plus mpv's Required/Recommended, per the one-level Recommended-deps policy.
    ("nasm",         "general/nasm.html",          "nasm-3.01.tar.xz"),
    ("libusb",       "general/libusb.html",        "libusb-1.0.29.tar.bz2"),
    ("dav1d",        "multimedia/dav1d.html",      "dav1d-1.5.3.tar.gz"),
    ("libaom",       "multimedia/libaom.html",     "libaom-3.13.1.tar.gz"),
    ("libvpx",       "multimedia/libvpx.html",     "libvpx-1.16.0.tar.gz"),
    ("x264",         "multimedia/x264.html",       "x264-20250815.tar.xz"),
    ("x265",         "multimedia/x265.html",       "x265_4.1.tar.gz"),
    ("lame",         "multimedia/lame.html",       "lame-3.100.tar.gz"),
    ("libass",       "multimedia/libass.html",     "libass-0.17.4.tar.xz"),
    ("svt-av1",      "multimedia/svt-av1.html",    "SVT-AV1-v4.0.1.tar.gz"),
    ("fdk-aac",      "multimedia/fdk-aac.html",    "fdk-aac-2.0.3.tar.gz"),
    ("libva",        "multimedia/libva.html",      "libva-2.23.0.tar.gz"),
    ("sdl3",         "multimedia/sdl3.html",       "SDL3-3.4.0.tar.gz"),
    ("sdl2-compat",  "multimedia/sdl2.html",       "sdl2-compat-2.32.64.tar.gz"),

    # --- Requested 2026-08-26: GNU Screen. Not part of the Hyprland/media-codec
    # stack -- queued as a quick standalone build. No hard deps (book's own
    # configure already passes --disable-pam, so the Optional Linux-PAM dep
    # doesn't apply).
    ("screen",       "general/screen.html",        "screen-5.0.1.tar.gz"),
]



# Steps with no BLFS book page. These recipes are HAND-AUTHORED, not extracted, and
# say so in their header so nobody mistakes them for book text.
EXTRA_STEPS = [
    {
        "name": "sshd-unit",
        "tarball": "blfs-systemd-units-20251204.tar.xz",
        "why": "The openssh page points at blfs-systemd-units for sshd.service; "
               "'make install-sshd' is that package's target, not openssh's.",
        "cmd": """# DESTDIR=/ installs to the right place AND makes the Makefile skip its
# `systemctl enable`, which cannot run in the chroot. Same trick, no patching.
make install-sshd DESTDIR=/

# Enable sshd.service by hand -- exactly what `systemctl enable` would do.
install -vdm755 /etc/systemd/system/multi-user.target.wants
ln -sfv /usr/lib/systemd/system/sshd.service \\
        /etc/systemd/system/multi-user.target.wants/sshd.service

# BLFS's sshd.service has no host-key generation, and sshd refuses to start without
# host keys. Generate them on first start instead of baking them into the image, so
# the tree stays safe to copy: ssh-keygen -A only creates what is missing.
install -vdm755 /etc/systemd/system/sshd.service.d
cat > /etc/systemd/system/sshd.service.d/keygen.conf << "EOF"
[Service]
ExecStartPre=/usr/bin/ssh-keygen -A
EOF

sshd -t -f /etc/ssh/sshd_config 2>&1 | grep -v "no hostkeys available" || true
echo "### sshd.service enabled; host keys generated on first start"
""",
    },
    {
        "name": "lfsmaint",
        "tarball": "lfsmaint-1.0.tar.gz",
        "why": "Installs the maintenance tooling into the target: package database, "
               "security advisory check, version drift, and a weekly timer. Packaged "
               "as a tarball so its install is a tracked step like any other package.",
        "cmd": """bash install.sh

# Seed the database inside the target from the manifests the harness recorded.
# --plan is not available here (the plans live on the build host), so the database
# is built on the host and copied in; this only verifies the tool runs.
/usr/sbin/lfsmaint --root / report 2>&1 | head -8 || \\
    echo "(no database yet -- built on the host and copied in)"
""",
    },
    {
        "name": "fix-varlog",
        "tarball": "",
        "why": "Remediation. ch07-createfiles block 5 was `exec /usr/bin/bash --login`, "
               "which replaced the shell and silently discarded block 6 -- the block that "
               "creates the login-accounting files. Re-running ch07-createfiles is NOT safe "
               "now: its `cat > /etc/passwd` would delete the sshd user OpenSSH added and "
               "re-add the tester account ch08-cleanup removed. So apply just the lost block.",
        "cmd": """# Exactly block 6 of LFS 13.0 section 7.6, and nothing else.
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

echo "### login accounting files:"
ls -l /var/log/{btmp,lastlog,faillog,wtmp}
""",
    },
    {
        "name": "claude-code",
        "tarball": "",
        "why": "Installs Claude Code from npm. Needs working DNS inside the chroot, "
               "which the LFS resolv.conf symlink cannot provide here.",
        "cmd": """# The chroot inherits host networking, but /etc/resolv.conf is a symlink to
# systemd-resolved's stub, which does not exist without a running resolved. Supply
# DNS for the duration of the install and restore the symlink no matter what.
_restore_resolv() {
    rm -f /etc/resolv.conf
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
}
trap _restore_resolv EXIT
rm -f /etc/resolv.conf
printf 'nameserver 1.1.1.1\\nnameserver 8.8.8.8\\n' > /etc/resolv.conf

npm install -g @anthropic-ai/claude-code

echo "### versions"
node --version
npm --version
claude --version
""",
    },
    {
        "name": "xorg-env",
        "tarball": "",
        "why": "x/xorg7.html: every Xorg/XCB-family BLFS recipe from here on "
               "(util-macros, xorgproto, libXau, libXdmcp, xcb-proto, libxcb, "
               "libxcvt, xcb-util, and later xorg-xwayland) uses $XORG_PREFIX "
               "and $XORG_CONFIG in its literal build commands -- the book "
               "has the reader export them once, persist them via "
               "/etc/profile.d, and reuse throughout. No page-specific "
               "command block captures this since it is shared setup, not "
               "part of any one package's page.",
        "cmd": """cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="/usr"
XORG_CONFIG="--prefix=\\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
chmod 644 /etc/profile.d/xorg.sh
echo "### written:"
cat /etc/profile.d/xorg.sh
""",
    },
    {
        "name": "mako",
        "tarball": "mako-1.3.10.tar.gz",
        "why": "general/python-modules.html covers dozens of Python modules "
               "on one page -- doesn't fit the one-page-per-package PACKAGES "
               "model the extractor uses everywhere else, so this is the "
               "book's own generic pattern (pip3 wheel, then pip3 install "
               "from the wheel) applied by hand. Required by Mesa's "
               "build-time code generation scripts (not a runtime dep).",
        "cmd": """pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user Mako
""",
    },
    {
        "name": "attrs",
        "tarball": "attrs-25.4.0.tar.gz",
        "why": "Not in BLFS. libei's book page lists it as Required "
               "('Required attrs-25.4.0') -- a pure-Python package, same "
               "pip3-wheel pattern as pyyaml/mako, except *without* "
               "--no-build-isolation: unlike pyyaml/mako (setuptools, "
               "already present), attrs' build backend is hatchling, not "
               "installed -- discovered via a real 'Cannot import "
               "hatchling.build' failure. Letting pip's normal isolated "
               "build fetch hatchling itself (this target has direct "
               "internet access, confirmed by every curl fetch this "
               "session) into a throwaway build venv is simpler and more "
               "honest than hand-vendoring hatchling as its own recipe; the "
               "final `pip3 install` step of *this* package still installs "
               "only the offline-built attrs wheel, no network involved. "
               "Sourced from PyPI directly (files.pythonhosted.org), sha256 "
               "verified against PyPI's own published digest for the "
               "25.4.0 sdist.",
        "cmd": """pip3 wheel -w dist --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user attrs
""",
    },
    {
        "name": "pyyaml",
        "tarball": "pyyaml-6.0.3.tar.gz",
        "why": "Same situation as blfs-mako. Required by Mesa's build-time "
               "code generation scripts. Its own Recommended deps "
               "(cython, libyaml, for C-accelerated parsing) skipped -- "
               "one-level policy, and this is a build-time tool only.",
        "cmd": """pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links dist --no-user PyYAML
""",
    },
    {
        "name": "xtrans",
        "tarball": "xtrans-1.6.0.tar.xz",
        "why": "Not in this BLFS mirror. Header-only X transport library, "
               "required by libx11's configure (discovered when libx11's "
               "build failed: 'Package xtrans not found'). Arch's official "
               "xtrans PKGBUILD as reference -- header-only, no compile "
               "step, just configure + install.",
        "cmd": """./configure $XORG_CONFIG
make install
""",
    },
    {
        "name": "libx11",
        "tarball": "libX11-1.8.13.tar.xz",
        "why": "Not in this BLFS mirror at all (confirmed: no libX11.html "
               "anywhere under book/blfs-13.0). Required by libglvnd "
               "(Arch's libglvnd PKGBUILD makedepends) and Mesa's x11 "
               "platform support. Built per Arch's official libx11 "
               "PKGBUILD, using this project's $XORG_CONFIG rather than "
               "Arch's own flags -- same convention as every other Xorg lib "
               "already built (xorgproto, libXau, libXdmcp, etc).",
        "cmd": """./configure $XORG_CONFIG --disable-xf86bigfont &&
make
make install
""",
    },
    {
        "name": "libxext",
        "tarball": "libXext-1.3.7.tar.xz",
        "why": "Same situation as blfs-libx11 -- not in this BLFS mirror, "
               "required by libglvnd and Mesa's x11 platform. Arch's "
               "libxext PKGBUILD as reference.",
        "cmd": """./configure $XORG_CONFIG &&
make
make install
""",
    },
    {
        "name": "libglvnd",
        "tarball": "libglvnd-v1.7.0.tar.gz",
        "why": "Not in BLFS at all. Vendor-neutral GL/EGL/GLX dispatch -- "
               "the piece that lets Mesa's nouveau path and (later, if "
               "installed) NVIDIA's proprietary libGL coexist and be "
               "switched via the opengl-driver mechanism, rather than one "
               "unconditionally overwriting the other's libGL.so. Arch's "
               "official libglvnd PKGBUILD as reference -- confirmed in "
               "extra, not AUR.",
        "cmd": """meson setup --prefix=/usr -D gles1=false build &&
ninja -C build
ninja -C build install
""",
    },
    {
        "name": "libevdev",
        "tarball": "libevdev-1.13.7.tar.xz",
        "why": "Not in BLFS. Required by libinput. Arch's official libevdev "
               "PKGBUILD as reference. tests=disabled added after a real "
               "build failure: the option defaults to enabled and hard-"
               "requires the Check unit test framework, not installed.",
        "cmd": """mkdir build && cd build
meson setup --prefix=/usr --buildtype=release -D documentation=disabled -D tests=disabled .. &&
ninja
ninja install
""",
    },
    {
        "name": "lua5.4",
        "tarball": "lua-5.4.9.tar.gz",
        "why": "Not in BLFS (which only has LuaJIT). libinput's device-quirk "
               "scripts want Lua 5.4 specifically via pkg-config as "
               "'lua5.4' -- distinct from the LuaJIT build mpv wants later, "
               "not interchangeable. Adapted from Arch's official lua54 "
               "PKGBUILD, simplified: skips Arch's parallel C++-linked "
               "lua++ variant (nothing here needs it) and the lua5.4-style "
               "renamed binaries/libs (no other Lua version on this system "
               "to conflict with) -- kept is exactly what matters for "
               "discovery: a lua5.4.pc pkg-config file naming the real "
               "library, which is what libinput's meson.build actually "
               "probes for. INSTALL_TOP=/usr added after a real failure: "
               "the upstream Makefile defaults INSTALL_TOP to /usr/local, "
               "which put the actual lib/headers/binaries in /usr/local "
               "while lua.pc (hardcoded prefix=/usr) pointed pkg-config at "
               "/usr -- a mismatch that would have made libinput's dependency "
               "probe find the .pc file but not the library it describes.",
        "cmd": """patch -Np1 -i ../liblua.so.patch
patch -Np1 -i ../paths.patch
sed "s/%VER%/5.4/g;s/%REL%/5.4.9/g" ../lua.pc > lua.pc

make MYCFLAGS="-fPIC" MYLDFLAGS="" linux-readline
make TO_LIB="liblua.so liblua.so.5.4 liblua.so.5.4.9" INSTALL_DATA='cp -d' INSTALL_TOP=/usr install
install -Dm644 lua.pc /usr/lib/pkgconfig/lua5.4.pc
ln -sf lua5.4.pc /usr/lib/pkgconfig/lua-5.4.pc
""",
    },
    {
        "name": "libinput",
        "tarball": "libinput-1.31.3.tar.gz",
        "why": "Not in BLFS. Recommended by Hyprland's own aquamarine "
               "backend and by libxkbcommon. Arch's official libinput "
               "PKGBUILD as reference; no -D documentation flag needed -- "
               "it's a boolean option (not a feature like most other "
               "packages this session) already defaulting to false, and "
               "passing 'disabled' to a boolean option is a hard meson "
               "configure error (discovered via a real failure). "
               "tests=false added for the same reason as libevdev's, though "
               "here the meson.build itself guards the Check dependency "
               "with required:false so it wouldn't have hard-failed. "
               "debug-gui=false added after a real failure: that boolean "
               "option also defaults to true and hard-requires GTK3/GTK4 "
               "for the libinput debug-events tool's GUI, neither of which "
               "is built yet on this system (GTK3 is a later tier).",
        "cmd": """mkdir build && cd build
meson setup --prefix=/usr --buildtype=release -D tests=false -D debug-gui=false .. &&
ninja
ninja install
""",
    },
    {
        "name": "seatd",
        "tarball": "seatd-0.9.3.tar.gz",
        "why": "Not in BLFS. Provides libseat, the session/seat abstraction "
               "aquamarine (Hyprland's backend layer) needs -- backed by "
               "this system's existing systemd-logind rather than the "
               "standalone seatd daemon (libseat-logind=systemd, "
               "server=disabled: no separate daemon needed when logind is "
               "already present). Arch's official seatd PKGBUILD as "
               "reference.",
        "cmd": """mkdir build
meson setup --prefix=/usr --buildtype=release \\
      -D libseat-logind=systemd \\
      -D server=disabled \\
      -D man-pages=disabled \\
      . build &&
ninja -C build
ninja -C build install
""",
    },
    {
        "name": "libxrender",
        "tarball": "libXrender-0.9.12.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency "
               "(confirmed in Arch's official hyprland PKGBUILD depends "
               "array: 'libxrender'), not just an XWayland transitive dep.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "libxfixes",
        "tarball": "libXfixes-6.0.2.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "libxcomposite",
        "tarball": "libXcomposite-0.4.7.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency, needs libxfixes (previous step).",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "libxcursor",
        "tarball": "libXcursor-1.2.3.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency. Arch "
               "also lists 'default-cursors' (a cursor-theme meta-package) "
               "as a runtime dep -- not a build requirement, skipped; a "
               "cursor theme is a later, separate concern.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "xcb-util-image",
        "tarball": "xcb-util-image-0.4.1.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency, needs xcb-util (already built).",
        "cmd": "./configure --prefix=/usr --disable-static\nmake\nmake install\n",
    },
    {
        "name": "xcb-util-keysyms",
        "tarball": "xcb-util-keysyms-0.4.1.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency.",
        "cmd": "./configure --prefix=/usr --disable-static\nmake\nmake install\n",
    },
    {
        "name": "xcb-util-renderutil",
        "tarball": "xcb-util-renderutil-0.3.10.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency.",
        "cmd": "./configure --prefix=/usr --disable-static\nmake\nmake install\n",
    },
    {
        "name": "xcb-util-wm",
        "tarball": "xcb-util-wm-0.4.2.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency.",
        "cmd": "./configure --prefix=/usr --disable-static\nmake\nmake install\n",
    },
    {
        "name": "xcb-util-errors",
        "tarball": "xcb-util-errors-1.0.1.tar.xz",
        "why": "Not in this BLFS mirror. Direct Hyprland dependency.",
        "cmd": "./configure --prefix=/usr\nmake\nmake install\n",
    },
    {
        "name": "libxscrnsaver",
        "tarball": "libXScrnSaver-1.2.5.tar.xz",
        "why": "Not in this BLFS mirror. SDL3's cmake hard-requires it "
               "(X11 Screen Saver extension) when X11 support is enabled -- "
               "discovered via a real configure failure ('Couldn't find "
               "dependency package for XSCRNSAVER'), not mentioned in "
               "SDL3's book page (which only lists the generic Xorg "
               "Libraries as part of Recommended). Arch's official libxss "
               "PKGBUILD as reference -- needs libxext, libx11, xorgproto "
               "(all already built).",
        "cmd": "./configure $XORG_CONFIG --sysconfdir=/etc\nmake\nmake install\n",
    },
    {
        "name": "libice",
        "tarball": "libICE-1.1.2.tar.xz",
        "why": "Not in this BLFS mirror. Required (hard) by pulseaudio's "
               "meson.build as 'ice' -- discovered via a real configure "
               "failure, not mentioned in pulseaudio's book page beyond "
               "the generic 'Xorg Libraries' Recommended entry. Arch's "
               "official libice PKGBUILD as reference -- needs xtrans, "
               "xorgproto (both already built).",
        "cmd": "./configure $XORG_CONFIG --sysconfdir=/etc\nmake\nmake install\n",
    },
    {
        "name": "libsm",
        "tarball": "libSM-1.2.6.tar.xz",
        "why": "Not in this BLFS mirror. Required (hard) alongside libice "
               "above by pulseaudio's meson.build as 'sm', same "
               "undocumented-chain discovery. Arch's official libsm "
               "PKGBUILD as reference -- needs libice (previous step), "
               "util-linux (already built in LFS ch8), xorgproto.",
        "cmd": "./configure $XORG_CONFIG --sysconfdir=/etc\nmake\nmake install\n",
    },
    {
        "name": "libxi",
        "tarball": "libXi-1.8.3.tar.xz",
        "why": "Not in this BLFS mirror. Required by libXtst below (found "
               "via a real at-spi2-core meson failure: 'Dependency xtst not "
               "found' -- at-spi2-core's book page only lists the generic "
               "'Xorg Libraries', not this specific transitive chain). "
               "Arch's official libxi PKGBUILD as reference -- needs "
               "libxext, libxfixes, libx11, xorgproto (all already built).",
        "cmd": "./configure $XORG_CONFIG --sysconfdir=/etc\nmake\nmake install\n",
    },
    {
        "name": "libxtst",
        "tarball": "libXtst-1.2.5.tar.xz",
        "why": "Not in this BLFS mirror. at-spi2-core hard-requires it "
               "(XTEST/RECORD extensions, for accessibility input "
               "injection) -- not mentioned in the book's dependency list "
               "at all, discovered via the same real failure as libxi "
               "above. Arch's official libxtst PKGBUILD as reference -- "
               "needs libxext, libxi (previous step), libx11, xorgproto.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "xorg-font-util",
        "tarball": "font-util-1.4.2.tar.xz",
        "why": "Not in this BLFS mirror as its own page. xwayland.html lists "
               "it as a Required dependency ('Xorg Fonts (only font-util)'). "
               "Arch's official xorg-font-util PKGBUILD as reference.",
        "cmd": """./configure $XORG_CONFIG
make
make install
""",
    },
    {
        "name": "libxkbfile",
        "tarball": "libxkbfile-1.2.0.tar.xz",
        "why": "Not in this BLFS mirror, and not listed in xwayland.html's "
               "documented dependency list either -- discovered only via a "
               "real xwayland meson configure failure ('Dependency xkbfile "
               "not found'); its meson.build hard-requires it with no "
               "required:false guard, unlike the adjacent libbsd-overlay "
               "and xkbcomp checks in the same block, which are genuinely "
               "optional. Arch's official libxkbfile PKGBUILD as reference "
               "(meson-based, needs libx11 and xorgproto, both already "
               "built).",
        "cmd": """mkdir build && cd build
meson setup --prefix=/usr --buildtype=release .. &&
ninja
ninja install
""",
    },
    {
        "name": "libfontenc",
        "tarball": "libfontenc-1.1.9.tar.xz",
        "why": "Not in this BLFS mirror. Required by libXfont2 below (found "
               "the same way -- xwayland's meson.build hard-requires "
               "'xfont2' with no book documentation of the chain). Arch's "
               "official libfontenc PKGBUILD as reference. Its own runtime "
               "dependency, xorg-fonts-encodings (encoding data tables), "
               "skipped: a data-only package needed for actually rendering "
               "legacy X11 core fonts at runtime, not for linking against "
               "the library, and this system has no legacy Xorg-Server "
               "installed to use them -- one-level policy, out of scope.",
        "cmd": """./configure --prefix=/usr --sysconfdir=/etc \\
      --localstatedir=/var --disable-static \\
      --with-encodingsdir=/usr/share/fonts/encodings &&
make
make install
""",
    },
    {
        "name": "libxfont2",
        "tarball": "libXfont2-2.0.9.tar.xz",
        "why": "Not in this BLFS mirror. Required (hard, unconditional) by "
               "xwayland's meson.build as 'xfont2', undocumented in the "
               "book's dependency list. Arch's official libxfont2 "
               "PKGBUILD builds from a git tag and autoreconfs -- used the "
               "equivalent upstream release tarball instead (same content, "
               "already carries a generated ./configure, no autoreconf "
               "needed) since it's simpler and this mirror has no md5/sha "
               "to verify a git checkout against anyway. No published "
               "checksum found for this tarball on xorg.freedesktop.org "
               "(no .sha256sum/.sig companion file); fetched directly over "
               "HTTPS and sanity-checked as a valid tar archive.",
        "cmd": """./configure --prefix=/usr --sysconfdir=/etc --disable-static &&
make
make install
""",
    },
    {
        "name": "libzip",
        "tarball": "libzip-1.11.4.tar.xz",
        "why": "Not in BLFS. Needed by hyprcursor (cursor theme archives are "
               "zip files). Arch's official libzip PKGBUILD as reference; "
               "built against whatever of its optional compression backends "
               "(zlib, bzip2, zstd, openssl) are actually present -- cmake "
               "auto-detects and skips the rest, same pattern used "
               "throughout this build.",
        "cmd": """cmake -B build -S . -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -Wno-dev
cmake --build build
cmake --install build
""",
    },
    {
        "name": "pugixml",
        "tarball": "pugixml-1.16.tar.gz",
        "why": "Not in BLFS. Needed by hyprwire. Arch's official pugixml PKGBUILD as reference.",
        "cmd": """cmake -B build -S . -W no-dev -D CMAKE_BUILD_TYPE=None -D BUILD_SHARED_LIBS=ON -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
""",
    },
    {
        "name": "re2",
        "tarball": "re2-2025-11-05.tar.gz",
        "why": "Not in BLFS. Needed by Hyprland itself, depends on "
               "abseil-cpp (already built). Arch's official re2 PKGBUILD as "
               "reference -- source there is a git tag clone, used here as "
               "GitHub's equivalent tag-tarball instead.",
        "cmd": """cmake -B build -S . -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_SHARED_LIBS=ON
cmake --build build
cmake --install build
""",
    },
    {
        "name": "tomlplusplus",
        "tarball": "tomlplusplus-3.4.0.tar.gz",
        "why": "Not in BLFS. Needed by hyprlang and hyprcursor. Arch's official tomlplusplus PKGBUILD as reference (meson-based).",
        "cmd": """meson setup --prefix=/usr --buildtype=release build .
ninja -C build
ninja -C build install
""",
    },
    {
        "name": "hyprwayland-scanner",
        "tarball": "hyprwayland-scanner-0.4.6.tar.gz",
        "why": "Not in BLFS. First of the Hyprland-ecosystem packages (all "
               "confirmed in Arch's official 'extra' repo, none in AUR, "
               "same pattern as htop) -- generates Wayland protocol "
               "bindings, needed to build aquamarine and Hyprland itself.",
        "cmd": """cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprutils",
        "tarball": "hyprutils-0.14.1.tar.gz",
        "why": "Not in BLFS. Needs pixman (already built). Foundation "
               "library for the rest of the Hyprland ecosystem.",
        "cmd": """cmake -W no-dev -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_TESTING=False -S . -B build
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprlang",
        "tarball": "hyprlang-0.6.8.tar.gz",
        "why": "Not in BLFS. Needs hyprutils.",
        "cmd": """cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprcursor",
        "tarball": "hyprcursor-0.1.13.tar.gz",
        "why": "Not in BLFS. Needs hyprlang, librsvg, libzip, cairo (all already built).",
        "cmd": """cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprgraphics",
        "tarball": "hyprgraphics-0.5.1.tar.gz",
        "why": "Not in BLFS. Needs hyprutils, cairo, pango, libjpeg-turbo, "
               "libpng, libwebp, libjxl, librsvg (all already built).",
        "cmd": """cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprwire",
        "tarball": "hyprwire-0.3.1.tar.gz",
        "why": "Not in BLFS. Needs hyprutils, libffi (already present), pugixml.",
        "cmd": """cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprland-protocols",
        "tarball": "hyprland-protocols-0.7.0.tar.gz",
        "why": "Not in BLFS. Wayland protocol definitions for the Hyprland ecosystem, meson-only, no other deps.",
        "cmd": """meson setup --prefix=/usr --buildtype=release build .
ninja -C build
ninja -C build install
""",
    },
    {
        "name": "glaze",
        "tarball": "glaze-8.1.0.tar.gz",
        "why": "Not in BLFS. Header-mostly JSON library, needed by Hyprland's own build.",
        "cmd": """cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_TESTING=OFF -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
""",
    },
    {
        "name": "aquamarine",
        "tarball": "aquamarine-0.14.0.tar.gz",
        "why": "Not in BLFS. The wlroots-successor rendering/backend layer "
               "Hyprland is built on -- needs hyprutils, "
               "hyprwayland-scanner, libdrm, libdisplay-info, libinput, "
               "libseat (from seatd), mesa, pixman, wayland, "
               "wayland-protocols (all already built).",
        "cmd": """cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build
""",
    },
    {
        "name": "iniparser",
        "tarball": "iniparser-4.2.6.tar.gz",
        "why": "Not in BLFS. Undocumented hard dependency of hyprtoolkit -- "
               "discovered via a real CMake configure failure ('required "
               "packages were not found: iniparser'), not mentioned in any "
               "Hyprland-ecosystem PKGBUILD's depends array since Arch's "
               "hyprtoolkit package itself doesn't declare it explicitly "
               "either (a transitive pkg-config probe, not a packaging-"
               "level dependency). Arch's official iniparser PKGBUILD as "
               "reference -- BUILD_STATIC_LIBS=false matches Arch's own "
               "build() flags.",
        "cmd": """cmake -S . -B build -D CMAKE_INSTALL_PREFIX=/usr -D BUILD_STATIC_LIBS=false
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprtoolkit",
        "tarball": "hyprtoolkit-0.5.4.tar.gz",
        "why": "Not in BLFS. Needed by hyprland-guiutils.",
        "cmd": """cmake -B build -W no-dev -D CMAKE_BUILD_TYPE=None -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
""",
    },
    {
        "name": "hyprland-guiutils",
        "tarball": "hyprland-guiutils-0.2.2.tar.gz",
        "why": "Not in BLFS. Needs hyprlang, hyprtoolkit, hyprutils, libdrm, pixman.",
        "cmd": """cmake -B build -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build
""",
    },
    {
        "name": "lua5.5",
        "tarball": "lua-5.5.1.tar.gz",
        "why": "Not in BLFS. Undocumented hard dependency of Hyprland "
               "itself -- discovered via a real CMake configure failure "
               "('None of the required lua55;lua5.5;lua-55;lua-5.5;"
               "lua>=5.5;lua<5.6 found'). Distinct from lua5.4 (libinput's "
               "dependency, built earlier) -- Lua's own major versions are "
               "not ABI/API compatible, both coexist on this system under "
               "different pkg-config names. Arch's official 'lua' PKGBUILD "
               "(now tracking 5.5.x, not 5.4) as reference: same "
               "liblua.so.patch/paths.patch/lua.pc pattern as lua5.4, "
               "re-fetched liblua.so.patch fresh since its context lines "
               "differ per-version (paths.patch and lua.pc are byte-"
               "identical to lua5.4's, confirmed by matching checksums). "
               "TO_BIN left at its default (unlike the rest of this "
               "recipe's deliberate deviations): this project's lua5.4 "
               "recipe already installs generic /usr/bin/lua directly (a "
               "deviation from Arch's versioned-binary approach made "
               "before lua5.5 was known to be needed), so installing "
               "lua5.5's binaries too overwrites lua5.4's /usr/bin/lua and "
               "/usr/bin/luac -- accepted rather than fought: TO_BIN=\"\" "
               "was tried first and fails outright (the Makefile's install "
               "rule has no guard for an empty file list, a real 'missing "
               "destination file operand' failure). Nothing on this system "
               "actually runs the Lua CLI, only pkg-config discovery "
               "matters for either version, so which binary ends up on "
               "PATH is immaterial. paths.patch (adds a /usr/ fallback to "
               "the interpreter's default LUA_PATH/LUA_CPATH search dirs, "
               "on top of /usr/local/) deliberately skipped here: it fails "
               "to apply cleanly against 5.5.1's luaconf.h (upstream "
               "reformatted macro/string spacing since the patch was "
               "written, a real failure discovered when this recipe was "
               "first run) and, since nothing runs the Lua interpreter "
               "itself on this system (library-only build), the runtime "
               "module search path it patches is moot anyway.",
        "cmd": """patch -Np1 -i ../liblua55.so.patch
sed "s/%VER%/5.5/g;s/%REL%/5.5.1/g" ../lua.pc > lua55.pc

make MYCFLAGS="-fPIC" MYLDFLAGS="" linux
make TO_LIB="liblua.so liblua.so.5.5 liblua.so.5.5.1" INSTALL_DATA='cp -d' INSTALL_TOP=/usr install
install -Dm644 lua55.pc /usr/lib/pkgconfig/lua55.pc
ln -sf lua55.pc /usr/lib/pkgconfig/lua5.5.pc
ln -sf lua55.pc /usr/lib/pkgconfig/lua-5.5.pc
""",
    },
    {
        "name": "hyprland",
        "tarball": "Hyprland-0.56.2.tar.gz",
        "why": "Not in BLFS. The compositor itself -- needs everything "
               "above plus lcms2, muparser (BLFS, already built), glib2 "
               "(already built), and the X11/XCB tier for XWayland "
               "integration. Uses Arch's exact source URL (the GitHub "
               "release's bundled 'source' tarball, not a plain git-tag "
               "archive -- Hyprland's own release process vendors things "
               "the plain tag archive would not include) and its top-level "
               "Makefile wrapper around the real cmake build.",
        "cmd": """sed -i -e '/^release:/{n;s/-D/-DCMAKE_SKIP_RPATH=ON -D/}' Makefile
make release PREFIX=/usr
make install
rm -fv /usr/include/hyprland/src/version.h.in

echo "### version"
hyprctl version 2>&1 || Hyprland --version 2>&1 || true
""",
    },
    {
        "name": "libxrandr",
        "tarball": "libXrandr-1.5.5.tar.xz",
        "why": "Not in this BLFS mirror. Discovered when vulkan-loader's "
               "cmake configure failed: 'required packages were not found: "
               "xrandr' -- vulkan-loader's X11 WSI backend needs the RandR "
               "extension library to enumerate displays. Needs libxext, "
               "libxrender, libx11 (all already built). Arch's official "
               "libxrandr PKGBUILD as reference.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "libxshmfence",
        "tarball": "libxshmfence-1.3.3.tar.xz",
        "why": "Not in this BLFS mirror. Discovered when mesa's meson "
               "configure failed: 'Dependency xshmfence not found' -- needed "
               "for DRI3 support on the x11 platform. Arch's official "
               "libxshmfence PKGBUILD as reference.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "libxxf86vm",
        "tarball": "libXxf86vm-1.1.7.tar.xz",
        "why": "Not in this BLFS mirror. Discovered when mesa's meson "
               "configure failed: 'Dependency xxf86vm not found' -- the "
               "X11 platform's video-mode-switching support. Arch's "
               "official libxxf86vm PKGBUILD as reference.",
        "cmd": "./configure $XORG_CONFIG\nmake\nmake install\n",
    },
    {
        "name": "pass",
        "tarball": "password-store-1.7.4.tar.xz",
        "why": "Not in BLFS. Checked AUR first per the standing two-tier "
               "policy -- not there either; pass is popular enough for "
               "Arch's official 'extra' repo. Arch's own PKGBUILD source is "
               "a git tag clone (git.zx2c4.com/password-store); fetched here "
               "via that same server's own snapshot endpoint "
               "(git.zx2c4.com/password-store/snapshot/password-store-1.7.4.tar.xz, "
               "verified reachable directly) rather than guessing a GitHub "
               "mirror name. Needs bash (have), gnupg, tree (both just "
               "built).",
        "cmd": """make DESTDIR=/ WITH_ALLCOMP=yes install
install -Dm0755 -t /usr/bin contrib/dmenu/passmenu

echo "### version"
pass version 2>&1 | head -3
""",
    },
    {
        "name": "linux-firmware-rtl-nic",
        "tarball": "",
        "why": "Baseline hardware audit (2026-08-25) found 'r8169 0000:06:00.0: Unable to "
               "load firmware rtl_nic/rtl8168e-3.fw (-2)' on every boot -- this is the "
               "machine's only network interface. BLFS's 'About Firmware' page confirms "
               "the driver works without it but says to install it once dmesg flags it "
               "missing. Fetches the one blob this NIC needs from the LFS project's "
               "official mirror, not the full linux-firmware tree (multi-GB, and the "
               "rest of it fixes hardware this box does not have).",
        "cmd": """install -vdm755 /usr/lib/firmware/rtl_nic
curl -fsSL --retry 5 --retry-delay 3 -o /usr/lib/firmware/rtl_nic/rtl8168e-3.fw \\
    https://anduin.linuxfromscratch.org/BLFS/linux-firmware/rtl_nic/rtl8168e-3.fw

echo "### installed:"
ls -l /usr/lib/firmware/rtl_nic/rtl8168e-3.fw
""",
    },
    {
        "name": "intel-microcode",
        "tarball": "",
        "why": "Baseline hardware audit (2026-08-25): CPU is an i5-2500K (family 6, model "
               "42, stepping 7 -> blob 06-2a-07) running microcode 0x28, applied once by "
               "the board's 2012 BIOS and never updated. The kernel's own 'bugs:' line "
               "in /proc/cpuinfo lists old_microcode and vmscape as unmitigated. BLFS's "
               "firmware.html is explicit that late loading is no longer supported "
               "upstream (the kernel taints and warns on it) -- early loading via a "
               "dedicated initrd is the only endorsed path. That reverses this system's "
               "original no-initramfs design (see BUILD-REPORT.md), a deliberate call "
               "made for this one purpose: the initrd carries nothing but this CPU's "
               "microcode blob, not a general-purpose early-boot environment.",
        "cmd": """MC_REL=microcode-20260812
curl -fsSL --retry 5 --retry-delay 3 -o microcode.tar.gz \\
    "https://api.github.com/repos/intel/Intel-Linux-Processor-Microcode-Data-Files/tarball/$MC_REL"
mkdir -p microcode-src
tar -xf microcode.tar.gz --strip-components=1 -C microcode-src

mkdir -p initrd/kernel/x86/microcode
cp -v microcode-src/intel-ucode/06-2a-07 initrd/kernel/x86/microcode/GenuineIntel.bin
( cd initrd && find * | cpio -o -H newc > /boot/microcode.img )

# /boot is not a separate partition on this system, so grub.cfg uses the
# in-root path form the book gives for that case. Idempotent re-run.
grep -q '^[[:space:]]*initrd /boot/microcode.img' /boot/grub/grub.cfg || \\
    sed -i '/^[[:space:]]*linux \\/boot\\/vmlinuz/a\\        initrd /boot/microcode.img' \\
        /boot/grub/grub.cfg
grub-script-check /boot/grub/grub.cfg

echo "### grub.cfg:"
cat /boot/grub/grub.cfg
echo "### initrd:"
ls -l /boot/microcode.img
""",
    },
    {
        "name": "iptables-unit",
        "tarball": "blfs-systemd-units-20251204.tar.xz",
        "why": "iptables.html's 'Systemd Unit' section: 'install the "
               "iptables.service unit included in the blfs-systemd-units "
               "package... make install-iptables'. Same package already used "
               "for sshd.service (blfs-sshd-unit) -- that target lives in "
               "blfs-systemd-units' own Makefile, not iptables', so it runs "
               "from this tree, separately. Unlike blfs-sshd-unit (built "
               "during the original chroot build, where systemctl could not "
               "run), this system is live now, so the Makefile's own "
               "'systemctl enable' runs for real -- no DESTDIR trick needed.",
        "cmd": """make install-iptables

echo "### enabled:"
systemctl is-enabled iptables.service
""",
    },
    {
        "name": "htop",
        "tarball": "",
        "why": "Not in the BLFS 13.0 book (checked: no book/blfs-13.0 page mentions it). "
               "Checked AUR first per the two-tier sourcing policy (BLFS when possible, "
               "else another distro's packaging as a build reference) -- zero AUR "
               "results, because htop is popular enough to live in Arch's official "
               "'extra' repo instead. Build recipe below is adapted from Arch's real "
               "PKGBUILD (gitlab.archlinux.org/archlinux/packaging/packages/htop), "
               "cross-checked against htop's own configure.ac rather than trusted "
               "blindly: --enable-sensors and --enable-delayacct need lm_sensors and "
               "libnl-3, neither installed here and neither worth a separate package "
               "for two optional features that auto-disable cleanly without them; "
               "--enable-openvz and --enable-vserver are in Arch's flag list but do not "
               "exist as options in this htop version at all (dead flags, dropped here "
               "rather than copied). --enable-capabilities (libcap) and --enable-unicode "
               "(ncursesw) are kept -- both already present from the base LFS build.",
        "cmd": """HTOP_VER=3.5.3
rm -rf htop
git clone --branch "$HTOP_VER" --depth 1 https://github.com/htop-dev/htop.git
cd htop
autoreconf -fi
./configure --prefix=/usr \\
            --sysconfdir=/etc \\
            --enable-affinity \\
            --enable-capabilities \\
            --enable-unicode
make
make install

echo "### version"
htop --version
""",
    },
    {
        "name": "skel-vimrc-and-root",
        "tarball": "",
        "why": "postlfs/vimrc.html's one example is a <pre class=\"screen\"> block (the "
               "book's own convention for 'not meant to be pasted verbatim', here just "
               "because vimrc comments use \" not #) -- the extractor only captures "
               "userinput/root blocks, so this doesn't come through the normal pipeline "
               "and is quoted here by hand instead, verbatim from the book. skel.html "
               "explicitly says the /etc/skel files 'can also copy... to the home "
               "directory of any other user already in the system', root included -- "
               "root has had no .bash_profile/.bashrc/.profile/.bash_logout since the "
               "original build (chapter 4's versions were for the temporary lfs build "
               "user, not root) and was living entirely off /etc/profile + /etc/bashrc.",
        "cmd": """cat > /etc/skel/.vimrc << "EOF"
" Begin .vimrc

set columns=80
set wrapmargin=8
set ruler

" End .vimrc
EOF
chmod 600 /etc/skel/.vimrc

for f in .bash_profile .profile .bashrc .bash_logout .vimrc; do
    cp -v /etc/skel/$f /root/$f
    chown root:root /root/$f
    chmod 600 /root/$f
done

echo "### /etc/skel:"
ls -la /etc/skel
echo "### /root:"
ls -la /root/.bash_profile /root/.profile /root/.bashrc /root/.bash_logout /root/.vimrc
""",
    },
    {
        "name": "adduser-john",
        "tarball": "",
        "why": "skel.html, 'When Adding a User': 'useradd -m <newuser>' -- -m copies "
               "/etc/skel into the new home directory, which is the entire point of "
               "having just built it. UID/GID land at 1000 (login.defs UID_MIN/GID_MIN, "
               "postlfs/users.html), the first ID above LFS's system-account range. "
               "Password locked deliberately (usermod -L): decided with the operator "
               "to create the account with no working auth yet rather than a "
               "temporary password or a key sight-unseen -- sshd already allows "
               "password auth (blfs-openssh block 5 was dropped for exactly this "
               "reason), so the account becomes reachable the moment a password or "
               "authorized_keys is added, whenever that happens.",
        "cmd": """useradd -m -s /bin/bash john
usermod -L john

echo "### passwd entry:"
getent passwd john
echo "### shadow entry (password field should be locked):"
getent shadow john
echo "### home dir:"
ls -la /home/john
""",
    },
]


def load_overrides():
    try:
        raw = json.load(open(OVERRIDES))
    except FileNotFoundError:
        return {}
    return {k: v for k, v in raw.items() if not k.startswith("_")}


def main():
    os.makedirs(OUT, exist_ok=True)
    overrides = load_overrides()
    plan = []
    queue = []

    for seq, (name, page, tarball) in enumerate(PACKAGES, 1):
        path = os.path.join(BOOK, page)
        src = open(path, encoding="utf-8", errors="replace").read()
        p = BlfsPageParser()
        p.feed(src)

        step = f"blfs-{name}"
        ov = overrides.get(step, {})
        n_on = 0
        lines = [
            "#!/bin/bash",
            f"# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.",
            f"# source : book/blfs-13.0/{page}",
            f"# title  : {p.title}",
            "# The driver supplies unpack/cd/cleanup. Commands below are in-package only.",
            "set -e",
            "",
        ]

        for i, b in enumerate(p.blocks):
            enabled, tags = lfsx.classify(b, name)
            decision = ov.get(str(i))
            if decision:
                act = decision["action"]
                if act in ("drop", "defer"):
                    enabled, tags = False, [f"REVIEWED:{act}"]
                elif act == "enable":
                    enabled, tags = True, []
                elif act == "replace":
                    enabled, tags = True, []
                    b["cmd"] = decision["cmd"]
            if tags and not decision:
                queue.append({"recipe": step, "block": i, "tags": tags,
                              "cmd": b["cmd"], "context": b["context"]})
            n_on += enabled

            lines.append(f"# --- block {i} " + ("-" * 50))
            if b["context"]:
                for cl in re.findall(r".{1,88}(?:\s|$)", b["context"]):
                    if cl.strip():
                        lines.append(f"#   ctx: {cl.strip()}")
            if not enabled:
                if decision:
                    lines.append(f"#   REVIEWED [{decision['action']}]: {decision['reason']}")
                else:
                    lines.append(f"#   TAGS: {' '.join(tags)}   [DISABLED - review]")
                lines.extend("# " + l for l in b["cmd"].splitlines())
            else:
                lines.append(b["cmd"])
            lines.append("")

        with open(f"{OUT}/{step}.sh", "w") as f:
            f.write("\n".join(lines) + "\n")

        plan.append({
            "seq": seq, "order": f"blfs.{seq}", "name": step,
            "chapter": "blfs", "page": name, "title": p.title,
            "context": "chroot", "tarball": tarball,
            "manifest": True,
            "blocks": len(p.blocks), "enabled": n_on,
            "disabled": len(p.blocks) - n_on,
        })
        print(f"  {step:18} {len(p.blocks):2} blocks, {n_on:2} enabled, "
              f"{len(p.blocks)-n_on:2} disabled   {p.title}")

    for k, e in enumerate(EXTRA_STEPS, len(PACKAGES) + 1):
        step = f"blfs-{e['name']}"
        body = [
            "#!/bin/bash",
            "# HAND-AUTHORED recipe -- no BLFS book page covers this step.",
            f"# rationale: {e['why']}",
            "set -e",
            "",
            e["cmd"],
        ]
        with open(f"{OUT}/{step}.sh", "w") as f:
            f.write("\n".join(body) + "\n")
        plan.append({
            "seq": k, "order": f"blfs.{k}", "name": step,
            "chapter": "blfs", "page": e["name"], "title": f"{e['name']} (hand-authored)",
            "context": "chroot", "tarball": e["tarball"], "manifest": True,
            "blocks": 1, "enabled": 1, "disabled": 0,
        })
        print(f"  {step:18} hand-authored")

    os.makedirs(STATE, exist_ok=True)
    with open(f"{STATE}/blfs-plan.json", "w") as f:
        json.dump(plan, f, indent=2)
    with open(f"{OUT}/blfs-review-queue.json", "w") as f:
        json.dump(queue, f, indent=2)

    print(f"\n{len(plan)} BLFS steps -> state/blfs-plan.json")
    print(f"{len(queue)} blocks awaiting review -> recipes/blfs-review-queue.json")


if __name__ == "__main__":
    main()
