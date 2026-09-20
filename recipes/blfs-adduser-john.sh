#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: skel.html, 'When Adding a User': 'useradd -m <newuser>' -- -m copies /etc/skel into the new home directory, which is the entire point of having just built it. UID/GID land at 1000 (login.defs UID_MIN/GID_MIN, postlfs/users.html), the first ID above LFS's system-account range.
#
# Password set 2026-09-01 (requested): unlocked with a known bootstrap password,
# 'lfs-changeme' -- same known-placeholder pattern ch08-shadow already uses for root
# ('CHANGE ON FIRST BOOT'), not a fresh usermod -L lock-out. This works alongside SSH
# password auth being disabled (blfs-overrides.json, blfs-openssh block 5) rather than
# against it: the password is for local/console login and su/sudo prompts, SSH itself
# is key-only regardless of what this account's password is set to.
#
# -G wheel added 2026-09-08: this step's seq (177) runs long after blfs-sudo's (15),
# whose own recipe adds john to wheel via `usermod -aG wheel john` -- fine on the live
# system, where john already existed from a much earlier point, but a genuine ordering
# bug on a fresh build, where sudo is built before this step ever creates the account at
# all. Adding wheel here directly (harmless no-op if john already exists, since the
# id-check below skips useradd entirely in that case) makes the end state correct
# regardless of which order the two steps actually ran in.
set -e

id john >/dev/null 2>&1 || useradd -m -G wheel -s /bin/bash john
echo "john:lfs-changeme" | chpasswd
echo "### john password set non-interactively to: lfs-changeme -- CHANGE ON FIRST BOOT"

echo "### passwd entry:"
getent passwd john
echo "### shadow entry:"
getent shadow john
echo "### home dir:"
ls -la /home/john

