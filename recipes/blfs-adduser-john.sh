#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: skel.html, 'When Adding a User': 'useradd -m <newuser>' -- -m copies /etc/skel into the new home directory, which is the entire point of having just built it. UID/GID land at 1000 (login.defs UID_MIN/GID_MIN, postlfs/users.html), the first ID above LFS's system-account range. Password locked deliberately (usermod -L): decided with the operator to create the account with no working auth yet rather than a temporary password or a key sight-unseen -- sshd already allows password auth (blfs-openssh block 5 was dropped for exactly this reason), so the account becomes reachable the moment a password or authorized_keys is added, whenever that happens.
set -e

useradd -m -s /bin/bash john
usermod -L john

echo "### passwd entry:"
getent passwd john
echo "### shadow entry (password field should be locked):"
getent shadow john
echo "### home dir:"
ls -la /home/john

