#!/bin/bash
# Standard X11 session launcher, run by `startx` (xinit). Replaces
# start-hyprland.sh from the Hyprland/Wayland era -- X11's own
# startx/xinit mechanism already does what that custom script had to
# do by hand (Wayland has no equivalent standard launcher).
#
# dunst is spawned from rc.lua's own Autostart block, not here --
# starting it before awesome was tried first and did not fix the
# D-Bus notification name conflict with awesome's `naughty` module
# (naughty claims the name synchronously during its own require,
# faster than dunst can initialize regardless of process start order).
# See rc.lua for the real fix (releasing the name explicitly, in a
# guaranteed order, before dunst is spawned).

exec awesome
