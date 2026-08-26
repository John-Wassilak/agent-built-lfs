#!/bin/bash
# HAND-AUTHORED recipe -- no scriptable BLFS page (see blfs-dejavu-fonts.sh
# for why).
# rationale: The operator's mirrored alacritty.toml explicitly configures
# "JetBrains Mono" as the terminal font -- installing DejaVu alone would
# leave Alacritty silently falling back to a substitute rather than the
# font actually requested. Version-matched against Arch's official
# ttf-jetbrains-mono (2.304). Static weights only (fonts/ttf/) --
# variable-font files skipped, matching BLFS's own guidance that variable
# fonts need explicit application support Alacritty doesn't need for a
# single fixed style.
set -e

install -v -d /usr/share/fonts/jetbrains-mono
install -v -m644 fonts/ttf/*.ttf /usr/share/fonts/jetbrains-mono/

fc-cache -f /usr/share/fonts/jetbrains-mono

echo "### verify"
fc-list | grep -i jetbrains | head -5
