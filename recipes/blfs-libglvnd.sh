#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS at all. Vendor-neutral GL/EGL/GLX dispatch -- the piece that lets Mesa's nouveau path and (later, if installed) NVIDIA's proprietary libGL coexist and be switched via the opengl-driver mechanism, rather than one unconditionally overwriting the other's libGL.so. Arch's official libglvnd PKGBUILD as reference -- confirmed in extra, not AUR.
set -e

meson setup --prefix=/usr -D gles1=false build &&
ninja -C build
ninja -C build install

