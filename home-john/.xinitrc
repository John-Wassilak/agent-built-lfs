#!/bin/bash
# Standard X11 session launcher, run by `startx` (xinit). Replaces
# start-hyprland.sh from the Hyprland/Wayland era -- X11's own
# startx/xinit mechanism already does what that custom script had to
# do by hand (Wayland has no equivalent standard launcher).

# dunst must start BEFORE awesome, not from rc.lua's own autostart
# block. Real bug found and fixed (2026-08-26): awesome's built-in
# `naughty` module claims the org.freedesktop.Notifications D-Bus name
# during awesome's own startup (rc.lua requires it near the top, for
# internal error popups) -- by the time rc.lua's autostart block later
# spawns dunst, naughty has already won the name and dunst fails
# ("Cannot acquire ... Name is acquired by 'naughty'"). Starting dunst
# here, before awesome even launches, means it wins that race instead.
dunst &

exec awesome
