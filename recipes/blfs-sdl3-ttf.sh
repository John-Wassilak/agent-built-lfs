#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this package.
# rationale: TrueType rendering for SDL3. FreeRDP's SDL3 client (sdl-freerdp) requires
# it for its dialogs: client/SDL/SDL3/dialogs/CMakeLists.txt find_package()s SDL3_ttf
# REQUIRED, which is why xsoft/freerdp.html passes WITH_CLIENT_SDL=OFF and says to remove
# that switch once SDL_ttf is installed. Configure as Arch extra's sdl3_ttf 3.2.2-3, with
# the dependency choices pinned: harfbuzz on (built), plutosvg off (color emoji, not
# built here), no vendored copies, and STRICT so a missing harfbuzz fails at configure
# instead of silently dropping shaping.
# source: github.com/libsdl-org/SDL_ttf/releases/download/release-3.2.2/
# SDL3_ttf-3.2.2.tar.gz. Detached signature verified good against Sam Lantinga's key
# 1528635D8053A57F77D1E08630A59377A7763BE6. sha512 matches Arch's PKGBUILD. sha256
# 63547d58d0185c833213885b635a2c0548201cc8f301e6587c0be1a67e1e045d.
set -e

cmake -B build -W no-dev                \
      -D CMAKE_INSTALL_PREFIX=/usr      \
      -D CMAKE_BUILD_TYPE=Release       \
      -D SDLTTF_VENDORED=OFF            \
      -D SDLTTF_STRICT=ON               \
      -D SDLTTF_HARFBUZZ=ON             \
      -D SDLTTF_PLUTOSVG=OFF            \
      -D SDLTTF_SAMPLES=OFF
cmake --build build
cmake --install build
