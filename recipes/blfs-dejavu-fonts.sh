#!/bin/bash
# HAND-AUTHORED recipe -- BLFS's TTF-and-OTF-fonts.html is a descriptive
# guide page (points at SourceForge's UI, no scriptable tarball/version),
# not a normal single-package recipe page.
# rationale: Not fetchable from BLFS's own page. Fixes real, confirmed
# breakage: zero fonts were installed anywhere on this system --
# `fc-list` returned nothing -- so every glyph rendered as a tofu box
# ("squares"), and GPU terminal/UI apps that can't find any usable font at
# all may fail outright rather than just look wrong. DejaVu gives full
# Latin/Greek/Cyrillic coverage (explicitly BLFS-endorsed, historically
# "strongly recommended" as the default Latin fallback). Version-matched
# against Arch's official ttf-dejavu (2.37) rather than assumed.
set -e

install -v -d /usr/share/fonts/dejavu
install -v -m644 ttf/*.ttf /usr/share/fonts/dejavu/
install -v -d /etc/fonts/conf.d
for f in fontconfig/*.conf; do
    install -v -m644 "$f" /etc/fonts/conf.d/
done

fc-cache -f /usr/share/fonts/dejavu

echo "### verify"
fc-list | grep -i dejavu | head -5
