#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this (proprietary, closed-source;
# never will be in BLFS).
# rationale: Operator-requested (2026-09-04). Slack ships Linux builds only as .deb/
# .rpm/Snap (confirmed against slack.com/downloads/linux -- no raw tarball option), so
# this unpacks the official .deb by hand with tools already in the closure (`ar` from
# binutils, `tar`) rather than bringing in dpkg. Staged at
# /sources/slack-desktop-4.52.155-amd64.deb (94MB, from
# downloads.slack-edge.com/desktop-releases/linux/x64/4.52.155/, the real URL the
# downloads page's own ddl redirect resolves to) since `tarball=""` in packages.py --
# the .deb's ar(1) container isn't something lfsbuild's `tar -xf` unpack wrapper
# understands, so this step does its own unpack instead of using it.
#
# `ldd` against the real binary (usr/lib/slack/slack) before writing this recipe found
# everything else already satisfied by this host's existing GTK3/Wayland/XWayland/
# pipewire/at-spi2 stack, except two:
#   - libffmpeg.so: ships inside the package itself (RPATH is $ORIGIN) -- no action
#     needed beyond installing it alongside the main binary.
#   - libcups.so.2: a genuine direct ELF NEEDED (Chromium's print backend links it,
#     doesn't dlopen it), and this host has never built CUPS. Operator's call
#     (2026-09-04): stub it rather than build the real BLFS cups.html chain --
#     Slack's print dialog will always show zero printers, nothing else. `readelf
#     --dyn-syms` against the real binary found 68 undefined symbols across cups*/
#     http*/ipp*/ppd* (a first pass that grepped for only "cups*" caught 26 of them
#     and produced a stub that loaded but crashed at `ppdOpenFd` on first run -- fixed
#     by re-deriving the full UND list rather than guessing at CUPS's surface). Each
#     stub returns 0/NULL/"" -- the same ABI shape CUPS itself returns with no server
#     or printers configured -- except the ipp_t/ipp_attribute_t "constructor" calls
#     (ippNew, ippAddString, etc.), which real callers never NULL-check because real
#     CUPS only fails those on malloc failure; those return a shared dummy non-NULL
#     pointer instead so the chain (build a request, add attributes, hand it to
#     cupsDoRequest) doesn't dereference NULL along the way. Not a reimplementation of
#     any real CUPS behaviour. Revisit as a real `book(...)` step if printing from
#     Slack is ever wanted.
#
# `etc/cron.daily/slack` (the .deb's own apt-based auto-updater) is deliberately not
# installed -- this system has no apt and no package manager for it to call.
# `chrome-sandbox` is installed setuid-root (matches every other distro's packaging of
# this same upstream binary) so Chromium's SUID sandbox actually engages instead of
# silently running renderer processes unsandboxed.
set -e

DEB=/sources/slack-desktop-4.52.155-amd64.deb
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
ar x "$DEB"
mkdir -p payload
tar -xJf data.tar.xz -C payload

install -d /usr/lib/slack /usr/share/applications /usr/share/doc/slack-desktop \
           /usr/share/pixmaps
cp -a payload/usr/lib/slack/. /usr/lib/slack/
install -Dm644 payload/usr/share/applications/slack.desktop \
               /usr/share/applications/slack.desktop
install -Dm644 payload/usr/share/doc/slack-desktop/OPEN_SOURCE_LICENSE_ATTRIBUTIONS \
               /usr/share/doc/slack-desktop/OPEN_SOURCE_LICENSE_ATTRIBUTIONS
install -Dm644 payload/usr/share/pixmaps/slack.png /usr/share/pixmaps/slack.png
ln -sfn ../lib/slack/slack /usr/bin/slack

chown root:root /usr/lib/slack/chrome-sandbox
chmod 4755 /usr/lib/slack/chrome-sandbox

# --- libcups.so.2 stub: see rationale above ---
cat > cups-stub.c << 'EOF'
/* Minimal ABI-compatible stand-in for libcups.so.2, covering every symbol Slack's
 * Electron/Chromium build references (the full `readelf --dyn-syms` UND list, not
 * just the cups*-prefixed ones -- see recipe comment for why that distinction
 * mattered). Deliberately untyped/no-arg definitions: on x86-64 SysV, every real
 * signature here returns via the single INTEGER class register (int, enum, and
 * pointer returns are ABI-identical) and none takes floating-point args, so the
 * caller's already-compiled argument setup is unaffected by what we declare, and
 * "return 0" is bit-identical to "return NULL". STUB0 covers every call whose real
 * CUPS counterpart legitimately returns 0/NULL/"not found" with no server or
 * printers present. STUBP covers only the ipp_t/ipp_attribute_t "constructor" and
 * "add" calls, which real callers never NULL-check (real CUPS fails those only on
 * malloc failure) -- returning a shared dummy address instead of NULL keeps a
 * build-request/add-attributes/send chain from dereferencing NULL along the way. */

static char dummy;
#define STUB0(name) long name() { return 0; }
#define STUBP(name) void *name() { return &dummy; }

const char *cupsLastErrorString(void) { return ""; }
const char *cupsServer(void) { return ""; }
const char *cupsUser(void) { return ""; }
const char *cupsUserAgent(void) { return ""; }
const char *ppdErrorString(void) { return ""; }

STUBP(ippNew)
STUBP(ippNewRequest)
STUBP(ippAddBoolean)
STUBP(ippAddCollection)
STUBP(ippAddCollections)
STUBP(ippAddInteger)
STUBP(ippAddRange)
STUBP(ippAddString)
STUBP(ippAddStrings)
STUBP(ippCopyAttribute)

STUB0(cupsCancelJob2)
STUB0(cupsCheckDestSupported)
STUB0(cupsCopyDest)
STUB0(cupsCopyDestInfo)
STUB0(cupsDoRequest)
STUB0(cupsEnumDests)
STUB0(cupsFindDestDefault)
STUB0(cupsFindDestSupported)
STUB0(cupsFreeDestInfo)
STUB0(cupsFreeDests)
STUB0(cupsGetDest)
STUB0(cupsGetDests2)
STUB0(cupsGetNamedDest)
STUB0(cupsGetOption)
STUB0(cupsGetPPD)
STUB0(cupsGetPPD2)
STUB0(cupsGetResponse)
STUB0(cupsLastError)
STUB0(cupsLocalizeDestValue)
STUB0(cupsMarkOptions)
STUB0(cupsRemoveDest)
STUB0(cupsSendRequest)
STUB0(cupsWriteRequestData)
STUB0(httpBlocking)
STUB0(httpClose)
STUB0(httpConnect2)
STUB0(httpConnectEncrypt)
STUB0(httpError)
STUB0(ippDelete)
STUB0(ippDeleteAttribute)
STUB0(ippFindAttribute)
STUB0(ippFirstAttribute)
STUB0(ippGetCollection)
STUB0(ippGetCount)
STUB0(ippGetGroupTag)
STUB0(ippGetInteger)
STUB0(ippGetName)
STUB0(ippGetRange)
STUB0(ippGetResolution)
STUB0(ippGetStatusCode)
STUB0(ippGetString)
STUB0(ippNextAttribute)
STUB0(ippPort)
STUB0(ippSetVersion)
STUB0(ippValidateAttributes)
STUB0(ppdClose)
STUB0(ppdFindAttr)
STUB0(ppdFindChoice)
STUB0(ppdFindMarkedChoice)
STUB0(ppdFindOption)
STUB0(ppdLastError)
STUB0(ppdMarkDefaults)
STUB0(ppdOpenFd)
EOF
gcc -shared -fPIC -Wl,-soname,libcups.so.2 -o /usr/lib/slack/libcups.so.2 cups-stub.c

echo "### runtime deps resolvable"
ldd /usr/lib/slack/slack | grep -i "not found" && echo "MISSING deps above" || echo "ok   all resolved"

echo "### version"
cat /usr/lib/slack/version 2>&1 || true
