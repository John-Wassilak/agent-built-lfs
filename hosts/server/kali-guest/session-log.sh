# SPDX-License-Identifier: MIT
# agent-built-lfs -- record every interactive terminal session in the Kali lab guest
# Copyright (c) 2026 John Wassilak

# The lab sheet asks for every terminal session to be recorded, and suggests
# `script -a ~/logs/$(date +%F).log`. This applies that to every session without
# anyone having to remember it. Install it in the guest, as root:
#   install -m 644 /mnt/share/session-log.sh /etc/session-log.sh
#   echo '. /etc/session-log.sh' >>/etc/zsh/zshrc
#   echo '. /etc/session-log.sh' >>/etc/bash.bashrc
# Those two rc files are read by every interactive zsh and bash, login or not, so
# qterminal windows, the VNC console and ssh all get it, for kali and for root.
# /etc/profile.d would miss the terminal windows, which are not login shells.
# kali-vm reset discards it with the rest of the overlay; reinstall after one.
#
# One file per session, not the sheet's one file per day: two terminals appending to
# the same file interleave their output. The name starts with the date, so
# ~/logs/2026-10-28_* is that day. Each log has a .timing file beside it, so
#   scriptreplay -t ~/logs/X.timing ~/logs/X.log
# replays the session at its real speed. -f flushes every write, so a guest crash or
# a reset loses nothing already on screen.
#
# The shell execs script, which starts a fresh shell inside the recording; that shell
# sees SESSION_LOG and leaves it alone, as does any shell started from it. Skipped:
# non-interactive shells, anything without a terminal (scp, `ssh host cmd`), and
# NO_SESSION_LOG=1. If ~/logs cannot be made the shell starts unrecorded, not dead.
# Works in bash and zsh.

if [ -z "${SESSION_LOG:-}" ] && [ -z "${NO_SESSION_LOG:-}" ] \
   && case $- in *i*) true ;; *) false ;; esac \
   && [ -t 0 ] && [ -t 1 ] && command -v script >/dev/null 2>&1 \
   && (umask 077; mkdir -p "$HOME/logs") 2>/dev/null && [ -w "$HOME/logs" ]; then
    SESSION_LOG="$HOME/logs/$(date +%F_%H%M%S)_$$.log"
    export SESSION_LOG
    # Created 0600 here so the shell inside keeps the user's own umask.
    (umask 077; : >>"$SESSION_LOG"; : >>"${SESSION_LOG%.log}.timing")
    exec script -q -a -f -T "${SESSION_LOG%.log}.timing" "$SESSION_LOG"
fi
