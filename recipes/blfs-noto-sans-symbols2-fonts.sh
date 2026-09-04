#!/bin/bash
# HAND-AUTHORED recipe -- no scriptable BLFS page (see blfs-dejavu-fonts.sh
# for why: TTF-and-OTF-fonts.html is a descriptive guide page, not a
# single-package recipe page).
# source: github.com/notofonts/symbols, release NotoSansSymbols2-v2.008
#
# rationale: operator-requested (2026-09-04). Noto Sans Symbols 2 is the
# symbol-coverage face of the Noto family. What it actually adds here was
# measured against the installed set rather than assumed, by differencing
# fc-query charsets across every font under /usr/share/fonts:
#
#   2953 codepoints in the font
#   1327 already covered by DejaVu / JetBrains Mono / Symbols Nerd Font
#   1626 new -- and those are the reason to install it
#
# Worth being precise about, because the obvious pitch for this font is
# wrong: DejaVu Sans already carries Braille (U+2800), playing cards
# (U+1F0A0) and the basic chess pieces (U+2654), so none of those is the
# gap. The real gap is:
#
#   U+1FB00-1FBCA  legacy computing -- block sextants, octants, the
#                  teletext/semigraphics set (202 new codepoints, the
#                  single largest block)
#   U+1FA00-1FA53  extended and fairy chess (84)
#   U+1F5A5-1F5FA  the non-emoji pictographs (86)
#   U+1F77B-1F7D9  astronomical/astrological and geometric extras (95)
#   U+1F000-1F02B  Mahjong tiles (44)
#   U+1F550-1F579  clock faces (42)
#   U+2B97-2BFD    misc symbols and arrows (103)
#   U+10140-1018E  Greek acrophonic numerals (79)
#   U+101D0-101FD  Phaistos Disc (46)
#
# Uncovered codepoints render as tofu boxes, the same way every glyph did
# before DejaVu was installed at seq 194.
#
# Shared, not host-specific: a font names no hardware.
#
# The zip published on that release is sha256
# 346c930bbe8eb946701a05c54e9c11a2094dee1d93c387bf1771c0a3e335688f;
# see packages.py for why it is staged as a .tar.gz instead.
set -e

# Four builds of the same face ship in this release, and they are not
# interchangeable. Counted with fc-query rather than assumed:
#
#   full/ttf        2953 codepoints   <- installed
#   googlefonts/ttf 2953 codepoints   same coverage, different hinting
#                                     metadata; what fonts.google.com serves
#   hinted/ttf      2639 codepoints   \ byte-identical to each other, and
#   unhinted/ttf    2639 codepoints   / 314 codepoints short of full
#
# `full` is the point of installing this font at all, so anything less
# would quietly reintroduce the tofu it is meant to remove. TTF rather than
# the OTF alongside it, matching how DejaVu and JetBrains Mono are already
# installed here.
install -v -d /usr/share/fonts/noto-sans-symbols2
install -v -m644 NotoSansSymbols2/full/ttf/NotoSansSymbols2-Regular.ttf \
    /usr/share/fonts/noto-sans-symbols2/

fc-cache -f /usr/share/fonts/noto-sans-symbols2

echo "### verify"
fc-list | grep -i 'symbols 2'

echo "### coverage -- codepoints no other installed font provides"
# fc-list ':charset=X', not `fc-match`: fc-match always answers with *some*
# family (it falls back rather than failing), so it cannot tell you whether
# a glyph is actually present anywhere -- it reported DejaVu Sans for a
# codepoint DejaVu does not have. fc-list with a charset pattern lists only
# fonts that really contain it, so an empty result before this install and a
# one-line result after is the real proof.
#   U+1FB00 BLOCK SEXTANT-1, U+1FA00 NEUTRAL CHESS KING, U+1F000 MAHJONG
#   TILE EAST WIND -- one from each of the three largest new blocks above.
for cp in 1FB00 1FA00 1F000; do
    printf 'U+%s: ' "$cp"
    fams=$(fc-list ":charset=$cp" family | sort -u | paste -sd'; ')
    [ -n "$fams" ] || { echo "NO FONT PROVIDES IT -- install did not take" >&2; exit 1; }
    echo "$fams"
done
