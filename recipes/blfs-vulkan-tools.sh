#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for Vulkan-Tools (the book
# covers Vulkan-Headers and Vulkan-Loader, but not the vulkaninfo/
# vkcube diagnostic tools built on top of them).
# source: github.com/KhronosGroup/Vulkan-Tools, tag v1.4.341 -- matches
#   the already-installed Vulkan-Loader-1.4.341.0's version exactly,
#   following the Khronos SDK's synchronized versioning across the
#   Vulkan-Headers/Vulkan-Loader/Vulkan-Tools trio.
# Rationale: operator-requested Vulkan/NVK verification after enabling
#   -D vulkan-drivers=nouveau in Mesa (see blfs-mesa.sh) -- need
#   vulkaninfo to confirm the driver actually initializes on real
#   hardware, not just that the ICD JSON was installed.
set -e

mkdir build
cd build

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -D BUILD_CUBE=OFF              \
      -G Ninja ..

ninja
ninja install

echo "### version"
vulkaninfo --summary 2>&1 || true
