#!/bin/bash
# HAND-AUTHORED recipe -- BLFS has a general/enchant.html page, but native
# mode has no book mirror on the target so it could not be extracted, and
# declaring book() would let the next extraction overwrite this file. Same
# reasoning as hand(79.1, "llvm", ...) and hand(230, "adwaita-icon-theme",
# ...) -- worth re-deriving as book() from a checkout that has the books.
# source: github.com/rrthomas/enchant, release v2.8.21
#
# rationale: operator-requested (2026-09-04), for jinx in Emacs. jinx builds
# a small dynamic module (jinx-mod.c) against `pkg-config enchant-2` and calls
# the enchant C API for every word, so it needs the library *and* its headers
# and .pc file -- all of which a normal --prefix=/usr install provides. Emacs
# on this system was checked first and does support it: /usr/include/emacs-module.h
# is present and `module-file-suffix` is ".so", so jinx will compile.
#
# Shared, not host-specific.
#
# Provenance: 2.8.21 is upstream's newest release and the sha256 of the
# release asset is dd2a762697c463148a8f59867089a5ebf2dd1449d869f93764b76c12bcf8acc0.
# Unlike hunspell and pass-otp, there is no second packager's hash to check it
# against -- Arch builds enchant from a git tag clone plus two gnulib
# submodules, so its recorded b2sum is over a source tree and is not
# comparable to a release tarball. Upstream publishes no detached signature
# for this release either.
set -e

# --with-hunspell explicitly, not left to configure's own detection. Every
# provider here is optional and auto-detected, so a build-order mistake --
# enchant landing at a lower seq than hunspell, say -- would produce an
# enchant with no backend at all: it configures clean, links clean, installs
# clean, and then reports every word as misspelled. That is precisely the
# failure mode PRACTICES.md's "pin the optional dependencies a recipe relies
# on" entry exists for, written up after pipewire silently lost ALSA the same
# way. With this flag a missing libhunspell fails at configure time instead.
#
# The other providers stay off because nothing here provides them: aspell,
# nuspell, hspell and voikko are not built on this system, and applespell,
# winspell and zemberek are for other platforms entirely.
./configure --prefix=/usr \
            --disable-static \
            --with-hunspell

make
make install

echo "### version"
pkg-config --modversion enchant-2

echo "### providers actually built"
ls -l /usr/lib/enchant-2/

echo "### dictionaries enchant can see"
# The real end-to-end check, and the one that would have caught a
# provider-less build: enchant-lsmod-2 asks the loaded providers what they
# have, so an empty list here means jinx would mark every word wrong no
# matter how cleanly everything compiled.
enchant-lsmod-2 -list-dicts
enchant-lsmod-2 -list-dicts | grep -q '^en_US' || {
    echo "enchant: no en_US dictionary visible -- provider or dictionary missing" >&2
    exit 1
}

echo "### spellcheck round-trip"
# enchant-2's own checker: '*' is a correctly spelled word, '&' introduces a
# misspelling with suggestions. Expect the first line ok and the second flagged.
printf 'correct\nspeling\n' | enchant-2 -d en_US -a | grep -vE '^$|^@'
