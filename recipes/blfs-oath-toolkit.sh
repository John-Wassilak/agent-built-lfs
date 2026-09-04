#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# source: Savannah, oath-toolkit-2.6.14 (download.savannah.nongnu.org/releases/oath-toolkit/)
#
# rationale: pulled in as the one hard runtime dependency of pass-otp -- otp.bash shells
# out to `oathtool` to compute the TOTP/HOTP code and does nothing else external (checked
# by grepping the script: `oathtool` and `which` are the only two programs it names).
# Not in BLFS, and not in Arch's AUR either -- oath-toolkit is in Arch's official `extra`
# repo, the same tier `pass` itself came from, so the standing two-tier policy that
# blfs-pass.sh records lands in the same place.
#
# Shared, not host-specific: a TOTP/HOTP implementation names no hardware.
#
# Tarball verified before use: the detached signature
# oath-toolkit-2.6.14.tar.gz.sig checks out as a good signature from
# "Simon Josefsson <simon@josefsson.org>", EdDSA subkey
# A3CC9C870B9D310ABAD4CF2F51722B08FE4745A2 under primary
# B1D2BD1375BECB784CF4F8C4D73CF638C53C06BE -- upstream's own maintainer. sha256 of the
# tarball is 8b1da365759f1249be57a82aec6e107f7b57dc77d813f96dc0aaf81624f28971.
set -e

# --disable-pam: this LFS system has no Linux-PAM at all (no /etc/pam.d, and
#   `loginctl list-sessions` correctly reports none) -- pam_oath would build a module
#   nothing could ever load.
# --disable-pskc: Portable Symmetric Key Container support, an XML key-provisioning
#   format used by nothing here. It drags in libxml2 as a link-time dependency of
#   libpskc and installs a pskctool that has no consumer on this box. pass-otp needs
#   liboath and the oathtool binary, and neither depends on it.
# --disable-static: house style, matching every other library step here.
./configure --prefix=/usr \
            --disable-static \
            --disable-pam \
            --disable-pskc

make
make install

echo "### version"
oathtool --version 2>&1 | head -2
echo "### smoke test -- RFC 4226 appendix D, HOTP counter 0 over the standard key"
# The RFC's own test vector, so a wrong answer here is a broken build rather than a
# broken expectation: seed 3132333435363738393031323334353637383930, counter 0 -> 755224.
got=$(oathtool -c 0 3132333435363738393031323334353637383930)
[ "$got" = "755224" ] || { echo "oathtool HOTP vector mismatch: got $got, want 755224" >&2; exit 1; }
echo "HOTP counter 0 = $got (matches RFC 4226)"
