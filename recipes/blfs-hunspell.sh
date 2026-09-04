#!/bin/bash
# HAND-AUTHORED recipe -- BLFS very likely has a page for this, but native
# mode has no book mirror on the target so it could not be extracted, and
# declaring book() would let the next extraction overwrite this file. Same
# reasoning as hand(79.1, "llvm", ...) and hand(230, "adwaita-icon-theme",
# ...) -- worth re-deriving as book() from a checkout that has the books.
# source: github.com/hunspell/hunspell, release v1.7.3
#
# rationale: operator-requested (2026-09-04), as the spelling backend under
# enchant-2 for jinx in Emacs. Enchant is only a dispatch layer -- it has no
# spelling engine of its own and ships providers for aspell, hunspell,
# nuspell, hspell and voikko, all of which are optional at its configure
# time. Without at least one provider *and* a dictionary, enchant builds
# clean, jinx compiles clean, and every word comes back misspelled.
#
# hunspell rather than nuspell or aspell: it is the format every distribution
# actually ships dictionaries in (the en_US pair installed by the next step
# is a hunspell .aff/.dic pair), it is plain C++ autotools with no dependency
# beyond the toolchain, and it is what BLFS itself carries. nuspell is the
# newer C++17 reimplementation and reads the same dictionaries, but adds a
# CMake build for no benefit here.
#
# Shared, not host-specific: a spell checker names no hardware.
#
# Tarball sha256 433274dac0619cb00c2e18b43a3dd3a9d50da5b5613fa9b5c21781e35dd76bc1,
# which is byte-for-byte the sum Arch pins in its own hunspell PKGBUILD.
set -e

./configure --prefix=/usr --disable-static

make
make install

echo "### version"
hunspell -vv 2>&1 | head -2
echo "### pkg-config"
pkg-config --modversion hunspell
