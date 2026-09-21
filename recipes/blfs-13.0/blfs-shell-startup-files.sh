#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/profile.html
# title  : The Bash Shell Startup Files
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: fs/wiki/bash-shell-startup-files /etc/profile Here is a base /etc/profile. This file
#   ctx: starts by setting up some helper functions and some basic parameters. It specifies some
#   ctx: bash history parameters and, for security purposes, disables keeping a permanent history
#   ctx: file for the root user. It then calls small, single purpose scripts in the
#   ctx: /etc/profile.d directory to provide most of the initialization.
cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/usr/bin

# Attempt to provide backward compatibility with LFS earlier than 11
if [ ! -L /bin ]; then
        pathappend /bin
fi

if [ $EUID -eq 0 ] ; then
        pathappend /usr/sbin
        if [ ! -L /sbin ]; then
                pathappend /sbin
        fi
        unset HISTFILE
fi

# Set up some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share}
export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script

# End /etc/profile
EOF

# --- block 1 --------------------------------------------------
#   ctx: The /etc/profile.d Directory Now create the /etc/profile.d directory, where the
#   ctx: individual initialization scripts are placed:
install --directory --mode=0755 --owner=root --group=root /etc/profile.d

# --- block 2 --------------------------------------------------
#   ctx: /etc/profile.d/extrapaths.sh This script adds some useful paths to the PATH and can be
#   ctx: used to customize other PATH related environment variables (e.g. LD_LIBRARY_PATH, etc)
#   ctx: that may be needed for all users.
cat > /etc/profile.d/extrapaths.sh << "EOF"
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

if [ -d /usr/local/share ]; then
        pathprepend /usr/local/share XDG_DATA_DIRS
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/info INFOPATH
EOF

# --- block 3 --------------------------------------------------
#   ctx: n, it's better to start its value with a colon (:), for example
#   ctx: MANPATH=:/opt/somepkg/share/man:/opt/otherpkg/share/man so the paths listed in the
#   ctx: MANPATH variable will be appended to the automatically deduced value instead of
#   ctx: overriding it. /etc/profile.d/readline.sh This script sets up the default inputrc
#   ctx: configuration file. If the user does not have individual settings, it uses the global
#   ctx: file.
cat > /etc/profile.d/readline.sh << "EOF"
# Set up the INPUTRC environment variable.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF

# --- block 4 --------------------------------------------------
#   ctx: /etc/profile.d/umask.sh Setting the umask value is important for security. Here the
#   ctx: default group write permissions are turned off for system users and when the user name
#   ctx: and group name are not the same.
cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF

# --- block 5 --------------------------------------------------
#   ctx: /etc/profile.d/i18n.sh This script sets an environment variable necessary for native
#   ctx: language support. A full discussion on determining this variable can be found on the
#   ctx: Configuring the System Locale page.
cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi
EOF

# --- block 6 --------------------------------------------------
#   ctx: Other Initialization Values Other initialization can easily be added to the profile by
#   ctx: adding additional scripts to the /etc/profile.d directory. /etc/bashrc Here is a base
#   ctx: /etc/bashrc. Comments in the file should explain everything you need.
cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.

if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for interactive shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# GnuPG wants this or it'll fail with pinentry-curses under some
# circumstances (for example signing a Git commit)
# Note that tty -s will "succeed" in LFS chroot environment so we cannot
# use -s instead of redirecting to /dev/null.
$(tty &>/dev/null) && export GPG_TTY=$(tty)

# End /etc/bashrc
EOF

# --- block 7 --------------------------------------------------
#   ctx: Node: Printing a Prompt. ~/.bash_profile Here is a base ~/.bash_profile. If you want
#   ctx: each new user to have this file automatically, just change the output of the command to
#   ctx: /etc/skel/.bash_profile and check the permissions after the command is run. You can then
#   ctx: copy /etc/skel/.bash_profile to the home directories of already existing users,
#   ctx: including root, and set the owner and group appropriately.
install -dm755 /etc/skel
cat > /etc/skel/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF
chmod 600 /etc/skel/.bash_profile

# --- block 8 --------------------------------------------------
#   ctx: ~/.profile Here is a base ~/.profile. The comments and instructions for using /etc/skel
#   ctx: for .bash_profile above also apply here. Only the target file names are different.
install -dm755 /etc/skel
cat > /etc/skel/.profile << "EOF"
# Begin ~/.profile
# Personal environment variables and startup programs.

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.profile
EOF
chmod 600 /etc/skel/.profile

# --- block 9 --------------------------------------------------
#   ctx: ~/.bashrc Here is a base ~/.bashrc.
install -dm755 /etc/skel
cat > /etc/skel/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.bashrc
EOF
chmod 600 /etc/skel/.bashrc

# --- block 10 --------------------------------------------------
#   ctx: ~/.bash_logout This is an empty ~/.bash_logout that can be used as a template. You will
#   ctx: notice that the base ~/.bash_logout does not include a clear command. This is because
#   ctx: the clear is handled in the /etc/issue file.
install -dm755 /etc/skel
cat > /etc/skel/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>

# Personal items to perform on logout.

# End ~/.bash_logout
EOF
chmod 600 /etc/skel/.bash_logout

# --- block 11 --------------------------------------------------
#   ctx: /etc/dircolors If you want to use the dircolors capability, then run the following
#   ctx: command. The /etc/skel setup steps shown above also can be used here to provide a
#   ctx: ~/.dircolors file when a new user is set up. As before, just change the output file name
#   ctx: on the following command and assure the permissions, owner, and group are correct on the
#   ctx: files created and/or copied.
dircolors -p > /etc/dircolors

