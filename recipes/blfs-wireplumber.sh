#!/bin/bash
# HAND-AUTHORED recipe from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/multimedia/wireplumber.html
# title  : Wireplumber-0.5.13
# rationale: pipewire's session manager -- required for pipewire to do
# automatic device management. Required: GLib (tier 11), pipewire (just
# built, this tier), systemd (already present). Recommended: Lua 5.4 (tier
# 8) -- -D system-lua=true uses it directly rather than pulling in a
# bundled copy.
#
# Gap found live 2026-09-04: this recipe originally stopped at `ninja
# install`, dropping the book's own "Configuring Wireplumber" section that
# comes right after Installation on this same page -- confirmed by reading
# wireplumber.html directly. Without it the systemd units exist on disk
# (confirmed: /usr/lib/systemd/user/{pipewire,pipewire-pulse}.{service,socket},
# wireplumber.service all present) but were never enabled, so nothing ever
# started them at login -- pavucontrol had no PulseAudio-protocol server to
# connect to. Added below, verbatim from the book: disable real PulseAudio's
# own autostart (this host built a full pulseaudio package for pavucontrol's
# client library, seq 209 -- its autostart .desktop/Xwayland-session.d/
# client.conf entries are real and would otherwise race wireplumber's own
# pipewire-pulse for the same protocol socket, exactly the book's documented
# "applications hanging" failure mode), then enable the three --global user
# units. `rm -vf` on files that may not exist and the two `&&`-joined halves
# both no-op cleanly if their target is already absent/already applied --
# safe on a --force rerun.
set -e

mkdir build
cd build

meson setup --prefix=/usr --buildtype=release -D system-lua=true ..
ninja

ninja install
mv -v /usr/share/doc/wireplumber /usr/share/doc/wireplumber-0.5.13

echo "### pkg-config"
pkg-config --modversion wireplumber-0.5 2>&1 || true

# --- Configuring Wireplumber (book's own next section, wireplumber.html) ---
rm -vf /etc/xdg/autostart/pulseaudio.desktop
rm -vf /etc/xdg/Xwayland-session.d/00-pulseaudio-x11
grep -q '^autospawn = no' /etc/pulse/client.conf 2>/dev/null || \
    sed -e '$a autospawn = no' -i /etc/pulse/client.conf

systemctl enable --global pipewire.socket
systemctl enable --global pipewire-pulse.socket
systemctl enable --global wireplumber
