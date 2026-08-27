#!/bin/bash
# Standard X11 session launcher, run by `startx` (xinit). Replaces
# start-hyprland.sh from the Hyprland/Wayland era -- X11's own
# startx/xinit mechanism already does what that custom script had to
# do by hand (Wayland has no equivalent standard launcher).
exec awesome
