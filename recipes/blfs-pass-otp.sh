#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# source: github.com/tadfisher/pass-otp, release v1.2.0
#
# rationale: operator-requested (2026-09-04). A `pass` extension that stores TOTP/HOTP
# secrets as ordinary pass entries (an otpauth:// URI line) and prints codes with
# `pass otp <name>`. Pure bash -- nothing to compile. Shared, not host-specific.
#
# Tarball verified before use: sha256
# 5720a649267a240a4f7ba5a6445193481070049c1d08ba38b00d20fc551c3a67, which is
# byte-for-byte the sum Arch pins in its own pass-otp PKGBUILD. Upstream publishes no
# detached signature for this release, so a second independent packager's recorded hash
# is the check available; it is the same two-tier policy blfs-pass.sh records.
#
# Runtime dependencies: pass (seq 222) and oathtool (blfs-oath-toolkit, built
# immediately before this). `which` is already present from seq 1. qrencode is NOT
# required despite Arch listing it: 1.2.0's otp.bash never invokes it (grepped, not
# assumed) -- QR rendering belongs to `pass show -q` in password-store itself, which is
# a separate optional feature of that package and unaffected either way.
set -e

# Upstream's install target hardcodes nothing awkward: SYSTEM_EXTENSION_DIR defaults to
# $(PREFIX)/lib/password-store/extensions, which is exactly the directory password-store
# 1.7.4 already created here and reads from, and BASHCOMPDIR defaults to
# /etc/bash_completion.d, which exists. So a plain PREFIX=/usr install is correct.
make PREFIX=/usr DESTDIR= install

# No PASSWORD_STORE_ENABLE_EXTENSIONS needed, contrary to most pass-otp write-ups.
# Checked against the installed /usr/bin/pass rather than assumed: cmd_extension() sets
# system_extension from SYSTEM_EXTENSION_DIR unconditionally and only gates
# user_extension (the per-store $PASSWORD_STORE_DIR/.extensions copy) behind that
# variable. A system-wide install like this one is live the moment the file lands.
echo "### installed:"
ls -l /usr/lib/password-store/extensions/otp.bash \
      /usr/share/man/man1/pass-otp.1 \
      /etc/bash_completion.d/pass-otp
