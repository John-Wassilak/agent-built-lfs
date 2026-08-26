#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Not in BLFS. Single bash script (no build), wraps grim+slurp+
# jq+wl-clipboard+libnotify (all already built) to provide screenshot
# keybindings -- operator-requested alongside alacritty. Version-matched
# against Arch's official package (1.3.0, confirmed via archlinux.org)
# rather than tracking main. No release tarball; fetched directly from the
# tagged ref. Note: this project's tags have no "v" prefix, unlike
# grim/slurp/alacritty -- confirmed via the GitHub API before guessing.
set -e

wget -q "https://raw.githubusercontent.com/Gustash/hyprshot/1.3.0/hyprshot" -O /usr/bin/hyprshot
chmod 755 /usr/bin/hyprshot

echo "### smoke test"
bash -n /usr/bin/hyprshot && echo "syntax OK"
