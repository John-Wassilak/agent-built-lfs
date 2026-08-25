#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter04/settingenvironment.html
# title  : 4.4. Setting Up the Environment
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Set up a good working environment by creating two new startup files for the bash shell.
#   ctx: While logged in as user lfs, issue the following command to create a new .bash_profile:
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# --- block 1 --------------------------------------------------
#   ctx: for the HOME, TERM, and PS1 variables. This ensures that no unwanted and potentially
#   ctx: hazardous environment variables from the host system leak into the build environment.
#   ctx: The new instance of the shell is a non-login shell, which does not read, and execute,
#   ctx: the contents of the /etc/profile or .bash_profile files, but rather reads, and executes,
#   ctx: the .bashrc file instead. Create the .bashrc file now:
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

# --- block 2 --------------------------------------------------
#   ctx: veral commercial distributions add an undocumented instantiation of /etc/bash.bashrc to
#   ctx: the initialization of bash. This file has the potential to modify the lfs user's
#   ctx: environment in ways that can affect the building of critical LFS packages. To make sure
#   ctx: the lfs user's environment is clean, check for the presence of /etc/bash.bashrc and, if
#   ctx: present, move it out of the way. As the root user, run:
#   REVIEWED [defer]: Real instruction from an Important admonition, but it runs as root on the HOST, not as the lfs user. Driver handles it in preflight. No-op here: Gentoo ships /etc/bash/bashrc, not /etc/bash.bashrc.
# [ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

# --- block 3 --------------------------------------------------
#   ctx: tel Core i9-13900K processor has 8 P (performance) cores and 16 E (efficiency) cores,
#   ctx: and a P core can simultaneously run two threads so each P core are modeled as two
#   ctx: logical cores by the Linux kernel. As the result there are 32 logical cores in total.
#   ctx: One obvious way to use all these logical cores is allowing make to spawn up to 32 build
#   ctx: jobs. This can be done by passing the -j32 option to make:
#   REVIEWED [drop]: Prose illustration, not an instruction. Book is explaining parallel make using a hypothetical i9-13900K with 32 logical cores. Running it would invoke make in $HOME with no target.
# make -j32

# --- block 4 --------------------------------------------------
#   ctx: Or set the MAKEFLAGS environment variable and its content will be automatically used by
#   ctx: make as command line options:
#   REVIEWED [drop]: Same prose illustration as block 3. The real MAKEFLAGS setting is block 5, which appends -j$(nproc) to .bashrc.
# export MAKEFLAGS=-j32

# --- block 5 --------------------------------------------------
#   ctx: Important Never pass a -j option without a number to make or set such an option in
#   ctx: MAKEFLAGS. Doing so will allow make to spawn infinite build jobs and cause system
#   ctx: stability problems. To use all logical cores available for building packages in Chapter
#   ctx: 5 and Chapter 6, set MAKEFLAGS now in .bashrc:
cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF

# --- block 6 --------------------------------------------------
#   ctx: Replace $(nproc) with the number of logical cores you want to use if you don't want to
#   ctx: use all the logical cores. Finally, to ensure the environment is fully prepared for
#   ctx: building the temporary tools, force the bash shell to read the new user profile:
source ~/.bash_profile

