#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: Header-only JSON library. fcitx5 5.1.23 links its keyboard engine against
# nlohmann_json::nlohmann_json unconditionally (src/im/keyboard/CMakeLists.txt), and
# nothing on this system provides it. Vietnamese input closure (operator request,
# 2026-10-21), see blfs-fcitx5.
# source: github.com/nlohmann/json release v3.12.0 asset json.tar.xz, saved as
# json-3.12.0.tar.xz. Detached signature json.tar.xz.asc verified good against Niels
# Lohmann's key 797167AE41C0A6D9232E48457F3CEA63AE251B69. sha256
# 42f6e95cad6ec532fd372391373363b62a14af6d771056dbfc86160e6dfff7aa.
set -e

cmake -B build -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_BUILD_TYPE=Release \
      -D JSON_BuildTests=OFF
cmake --build build
cmake --install build
