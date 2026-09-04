#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step, and never will: it is a
# single POSIX shell script with no build system of its own (confirmed by reading the
# repo tree -- LICENSE, README.md, hyprshot, nothing else).
# rationale: Operator-requested (2026-09-04). Screenshot utility for Hyprland, wrapping
# grim/slurp/hyprctl. Its own README lists real deps: hyprland (have), jq, grim, slurp,
# wl-clipboard (all four just built, this tier), libnotify (already built, tier 154).
# hyprpicker, the one optional dep (README: "to freeze the screen contents with the
# --freeze flag"), is not built here -- the script itself gates every call behind
# `command -v hyprpicker`, so --freeze degrades to a normal capture rather than
# failing, and nothing else in this project's plan wants hyprpicker for its own sake.
# Add it later, as its own step, if --freeze turns out to be wanted.
set -e

install -Dm755 hyprshot /usr/bin/hyprshot
install -Dm644 LICENSE  /usr/share/licenses/hyprshot/LICENSE

echo "### all runtime deps resolvable"
for dep in jq grim slurp wl-copy hyprctl notify-send; do
    command -v "$dep" >/dev/null 2>&1 && echo "ok   $dep" || echo "MISSING $dep"
done

echo "### version"
head -1 /usr/bin/hyprshot
