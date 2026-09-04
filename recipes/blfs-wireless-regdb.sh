#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# source: kernel.org, wireless-regdb-2026.09.03
#
# rationale: found on laptop 2026-09-04, in the first dmesg after the reboot into the
# media/USER_NS kernel, 0.35 s into boot:
#
#   faux_driver regulatory: Direct firmware load for regulatory.db failed with error -2
#
# -2 is ENOENT. cfg80211 is built in (CONFIG_CFG80211=y) and asks the firmware loader
# for the wireless regulatory database at init; nothing on this system had ever
# installed one, on either host. Without it the kernel falls back to the world-roaming
# domain "00", which is the intersection of every jurisdiction: 2.4 GHz channels 12-14
# are unusable, most of 5 GHz is passive-scan-only or absent, and tx power is capped
# well under what the local domain permits. It is not an error a user sees -- it
# presents as an access point that "does not show up" or a link that is slower than the
# same card on any other distro.
#
# Shared, not host-specific, by the test in CLAUDE.md: this names no device, no vendor,
# no chipset and no filesystem. It is one database for every radio, and any machine in
# this repo with a wireless card wants it. (Today that is only laptop -- server has no
# radio -- but nothing here is laptop-shaped.)
#
# hand(), not book(): whether BLFS 13.0 has a page for this could not be checked, since
# native mode has no book mirror on the target. Declaring book() would let the next
# extraction overwrite this file. Same reasoning as hand(79.1, "llvm", ...) and
# hand(230, "adwaita-icon-theme", ...) -- worth re-deriving from a checkout that has the
# books.
set -e

# --- why this does not run `make install` -----------------------------------------
# Two reasons, both checked against the Makefile in this exact tarball rather than
# assumed:
#
# 1. `make install` also installs regulatory.bin into /usr/lib/crda and
#    wens.key.pub.pem into /usr/lib/crda/pubkeys. Those are the *legacy* CRDA path: a
#    userspace helper that udev invokes on a REGDOM_CHANGE uevent, which the kernel
#    only consults when it cannot load regulatory.db itself. This system has no crda
#    binary and none is planned, so those two files would create a /usr/lib/crda that
#    nothing can ever read. Same policy as this host's three linux-firmware steps:
#    install what the machine actually loads, not the whole upstream tree.
#
# 2. More important, a caution for anyone who edits this later. The Makefile's
#    `regulatory.bin` rule lists $(REGDB_PRIVKEY) as a prerequisite and the rule for
#    *that* is `openssl genrsa` -- make will silently mint a throwaway private key and
#    re-sign the database with it if anything drags those rules in. A regulatory.db
#    signed by a locally generated key is exactly what this kernel refuses: it is
#    built with CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=y and
#    CONFIG_CFG80211_USE_KERNEL_REGDB_KEYS=y, so it validates the .p7s against the
#    certificates compiled into net/wireless/certs/ and nothing else. Installing the
#    prebuilt, upstream-signed pair straight out of the tarball cannot hit that.

# --- verify the signature before installing anything -------------------------------
# This mirrors what the kernel will do at boot, so a failure here is a real failure
# and not belt-and-braces. Two checks:
#
#   a. the PKCS#7 detached signature actually validates over regulatory.db, and
#   b. the certificate that signed it is one the kernel trusts.
#
# For (b) the fingerprints below are read out of linux-6.18.10's own
# net/wireless/certs/*.hex -- the DER blobs the kernel compiles in. sforshee is Seth
# Forshee, the long-time regdb maintainer; wens is Chen-Yu Tsai, who signs the current
# releases. If upstream ever rotates to a third key this exits 1, which is correct:
# that database would boot to the same "00" domain it is meant to fix.
KERNEL_REGDB_CERTS="\
CA:D3:DD:C5:F2:74:B8:21:3C:99:56:E2:61:1A:41:52:52:FD:36:19:CA:67:00:DC:8E:D3:96:ED:23:AC:F6:B0
EE:B0:49:59:4E:B3:A8:3E:50:BF:B6:78:2E:7F:DF:9E:96:FB:D5:C2:95:4A:0B:BB:09:31:CD:55:32:1D:0B:CF"

SIGNER_CERT=$(ls *.x509.pem | head -1)
[ -n "$SIGNER_CERT" ] || { echo "wireless-regdb: no signing certificate in the tarball" >&2; exit 1; }

openssl smime -verify -inform DER -in regulatory.db.p7s -content regulatory.db \
    -certfile "$SIGNER_CERT" -nointern -noverify -out /dev/null \
  || { echo "wireless-regdb: regulatory.db.p7s does not verify over regulatory.db" >&2; exit 1; }

FP=$(openssl x509 -in "$SIGNER_CERT" -noout -fingerprint -sha256 | sed 's/.*=//')
echo "$KERNEL_REGDB_CERTS" | grep -qxF "$FP" || {
    echo "wireless-regdb: $SIGNER_CERT ($FP) is not a key this kernel trusts" >&2
    echo "wireless-regdb: expected one of --" >&2
    echo "$KERNEL_REGDB_CERTS" >&2
    exit 1
}
echo "### signed by $SIGNER_CERT, $FP -- trusted by net/wireless/certs"

# --- install ------------------------------------------------------------------------
# /usr/lib/firmware, written directly rather than through the /lib -> usr/lib symlink
# the Makefile's FIRMWARE_PATH default uses. Both man pages, not just regulatory.db.5:
# that one is a single `.so man5/regulatory.bin.5.gz` redirect and is a dangling
# reference without its target. Gzipped, matching every other man page here.
install -vdm755 /usr/lib/firmware
install -vm644 regulatory.db regulatory.db.p7s /usr/lib/firmware/

install -vdm755 /usr/share/man/man5
for m in regulatory.bin.5 regulatory.db.5; do
    gzip -c "$m" > "/usr/share/man/man5/$m.gz"
    chmod 644 "/usr/share/man/man5/$m.gz"
done

echo "### installed:"
ls -l /usr/lib/firmware/regulatory.db /usr/lib/firmware/regulatory.db.p7s
