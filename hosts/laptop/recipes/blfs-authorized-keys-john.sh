#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step. Host-specific.
#
# Installs john's authorized_keys from an untracked file rather than carrying the keys
# inline. They used to be inline, on the reasoning that public keys are not secret; true,
# but the list is still "who can log into this machine", and this repo is public. The
# keys now live in hosts/<host>/authorized-keys.local (.gitignore;
# authorized-keys.local.example is the tracked template), staged to
# /sources/authorized-keys.local before the build -- same convention as kernel-config.sh.
#
# Required, not optional: blfs-openssh block 5 disables password authentication, so a
# build that installs no authorized_keys has no SSH access at all. Missing input is a
# hard error here rather than a silently empty file. Must run after adduser-john and
# after openssh.
set -e

KEYS=/sources/authorized-keys.local

if [ ! -s "$KEYS" ]; then
    echo "### $KEYS is missing or empty." >&2
    echo "### SSH password auth is disabled (blfs-openssh block 5), so installing no" >&2
    echo "### authorized_keys would lock this build out of SSH entirely. Stage the file" >&2
    echo "### from hosts/<host>/authorized-keys.local and re-run." >&2
    exit 1
fi

install -v -d -m700 -o john -g john /home/john/.ssh

grep -vE '^\s*(#|$)' "$KEYS" > /home/john/.ssh/authorized_keys

if [ ! -s /home/john/.ssh/authorized_keys ]; then
    echo "### $KEYS contained no key lines (comments only)." >&2
    exit 1
fi

chown john:john /home/john/.ssh/authorized_keys
chmod 600 /home/john/.ssh/authorized_keys

echo "### authorized_keys installed:"
wc -l < /home/john/.ssh/authorized_keys
