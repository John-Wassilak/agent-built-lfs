#!/bin/bash
# Standard way to start the X11/awesome desktop from a physical console
# login (no display manager), on the NVIDIA 470.xx driver test boot
# (GRUB entry 1). Successor to start-hyprland.sh -- kept the same
# log-redirection pattern for troubleshooting, since startx/Xorg's own
# console output is otherwise easy to lose.
set -e

export XDG_RUNTIME_DIR="/run/user/$(id -u)"

LOG="$HOME/awesome.log"
[ -f "$LOG" ] && mv -f "$LOG" "$LOG.old"

mkdir -p "$HOME/screens"

exec startx -- vt1 > "$LOG" 2>&1
