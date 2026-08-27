#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for libvdpau (this project
# never needed VDPAU before tonight -- nouveau's own VDPAU state tracker
# was removed in Mesa 25.3.0+, and VAAPI was the only decode path
# attempted until now).
# source: gitlab.freedesktop.org/vdpau/libvdpau, tag 1.5 (latest, 2022 --
#   the project has been stable/inactive since).
# Rationale: vendor-neutral VDPAU dispatch library. NVIDIA's own
# libvdpau_nvidia.so (installed by the 470xx driver, see
# blfs-nvidia-470xx.sh) is a *vendor* VDPAU driver -- applications link
# against libvdpau.so itself, which is this package, and it dlopens the
# vendor driver by name at runtime. Confirmed via meson's dependency
# check (dri2proto/x11 required) that VDPAU's device-creation API is
# inherently X11-tied (vdp_device_create_x11) -- there is no DRM-render-
# node-only path the way VAAPI has.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release ..
ninja
ninja install
