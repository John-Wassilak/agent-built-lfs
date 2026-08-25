#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter04/addinguser.html
# title  : 4.3. Adding the LFS User
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: age or destroy a system. Therefore, the packages in the next two chapters are built as
#   ctx: an unprivileged user. You could use your own user name, but to make it easier to set up
#   ctx: a clean working environment, we will create a new user called lfs as a member of a new
#   ctx: group (also named lfs) and run commands as lfs during the installation process. As root,
#   ctx: issue the following commands to add the new user:
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

# --- block 1 --------------------------------------------------
#   ctx: lt is /etc/skel) by changing the input location to the special null device. lfs This is
#   ctx: the name of the new user. If you want to log in as lfs or switch to lfs from a non-root
#   ctx: user (as opposed to switching to user lfs when logged in as root, which does not require
#   ctx: the lfs user to have a password), you need to set a password for lfs. Issue the
#   ctx: following command as the root user to set the password:
#   REVIEWED [drop]: Interactive password prompt; would hang the driver. The lfs account is reached via sudo -u lfs and needs no password.
# passwd lfs

# --- block 2 --------------------------------------------------
#   ctx: Grant lfs full access to all the directories under $LFS by making lfs the owner:
chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

# --- block 3 --------------------------------------------------
#   ctx: Note In some host systems, the following su command does not complete properly and
#   ctx: suspends the login for the lfs user to the background. If the prompt "lfs:~$" does not
#   ctx: appear immediately, entering the fg command will fix the issue. Next, start a shell
#   ctx: running as user lfs. This can be done by logging in as lfs on a virtual console, or with
#   ctx: the following substitute/switch user command:
#   REVIEWED [drop]: Book instructs a human reader to become the lfs user for Chapters 5-6. As a driver step it would open an interactive shell and hang. The driver switches context per step via sudo -u lfs with the book's exact environment.
# su - lfs

