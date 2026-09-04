#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step. BLFS's hunspell
# page points at dictionary downloads rather than packaging one, the same way
# its TTF-and-OTF-fonts page points at font downloads (see
# blfs-dejavu-fonts.sh).
# source: SCOWL / wordlist.sourceforge.net, hunspell-en_US-2020.12.07
#
# rationale: operator-requested (2026-09-04). hunspell is an engine with no
# words in it; this is the American English word list it reads. Without it
# `enchant-lsmod-2 -list-dicts` returns nothing and jinx marks every word
# wrong -- the failure looks like a broken enchant install rather than a
# missing dictionary, which is why this is its own numbered step and not a
# footnote in the hunspell recipe.
#
# SCOWL's release rather than the LibreOffice dictionaries repo: SCOWL is the
# upstream both derive from, it publishes discrete versioned releases instead
# of a rolling git tree, and it is what Arch's and Debian's own en_US hunspell
# packages are built from. 2020.12.07 is its newest release -- the word list
# is not on a frequent cadence.
#
# Shared, not host-specific.
#
# Provenance is thinner here than for the other two steps in this group and
# worth saying plainly: upstream publishes no signature, and no second
# packager's recorded hash was found to cross-check against (Arch's
# hunspell-en_US PKGBUILD did not resolve). What is recorded is the sha256 of
# the zip as fetched, 616348ad645a716d91c8a6645065e710f15e9dda3ffef60cdf7ec8a4e27975af.
# It is a word list, not code -- hunspell parses it as data -- which is why
# that was judged acceptable rather than blocking.
#
# Staged as .tar.gz: the upstream artifact is a .zip, lfsbuild's unpack step is
# a plain `tar -xf` with no zip path, and this zip has no top-level directory
# for srcdir_of() to find. Repacked under a hunspell-en_US-2020.12.07/ prefix
# with identical contents -- same handling JetBrainsMono-2.304.zip and
# NotoSansSymbols2-v2.008.zip already get here.
set -e

# /usr/share/hunspell, and that path is not folklore -- it is what enchant's
# own provider looks at. providers/enchant_hunspell.cpp's
# s_buildDictionaryDirs() walks g_get_system_data_dirs() (this system's
# XDG_DATA_DIRS, /usr/local/share:/usr/share) and appends the provider name,
# so /usr/share/hunspell is on the search path and a dictionary is only found
# when the .dic and its matching .aff are both present.
install -v -d /usr/share/hunspell
install -v -m644 en_US.aff en_US.dic /usr/share/hunspell/

# The word list's own README carries its license and provenance; keep it with
# the package rather than discarding it.
install -v -d /usr/share/doc/hunspell-en_US-2020.12.07
install -v -m644 README_en_US.txt /usr/share/doc/hunspell-en_US-2020.12.07/

echo "### installed:"
ls -l /usr/share/hunspell/
echo "### hunspell sees it:"
echo "correctly speled sentance" | hunspell -d en_US -l
