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

# --- Hardware video decode for Firefox (nvidia-vaapi-driver, packages.py seq 255) ---
# Added 2026-09-22. These are session-wide because they must reach Firefox and any
# other VA-API client; they are environment, not build configuration, which is why
# they live here rather than in the recipe. The matching Firefox prefs are in that
# profile's user.js -- both halves are required.
#
# LIBVA_DRIVER_NAME: libva 2.24 no longer guesses a driver for this device
# (vaGetDriverNames() fails), so the driver has to be named explicitly. Without it
# vainfo and Firefox both fall back to software decode silently.
export LIBVA_DRIVER_NAME=nvidia
# __EGL_VENDOR_LIBRARY_FILENAMES: required for the 470 series specifically, per the
# driver's README. /usr/share/glvnd/egl_vendor.d holds both 10_nvidia.json and
# 50_mesa.json, and pinning the list stops glvnd handing Firefox the mesa EGL vendor
# by mistake, which breaks the driver's buffer export.
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
# MOZ_DISABLE_RDD_SANDBOX: the decoder runs in Firefox's RDD process, whose sandbox
# blocks the NVIDIA device access this driver needs. This is a real reduction in
# sandboxing of the media process, accepted knowingly for hardware decode.
export MOZ_DISABLE_RDD_SANDBOX=1

exec awesome
