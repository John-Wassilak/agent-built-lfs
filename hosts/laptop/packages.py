# SPDX-License-Identifier: GPL-3.0-or-later
#
# agent-built-lfs -- BLFS build plan for `laptop`
# Copyright (C) 2026 John Wassilak
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://www.gnu.org/licenses/>.

"""BLFS build plan for `laptop` -- nothing beyond the shared core yet.

BASE is the closure that makes an LFS system workable: CA store, Node.js for Claude
Code, ssh, curl/wget/git, sudo, iptables. It is what `server` was verified on, so it is
the right first target here too -- get to a box you can log into and run Claude Code on
before deciding anything about a desktop.

What to add after that, and what NOT to copy from `server`:

  seq 17-  server's desktop stack is NVIDIA 470.xx + VDPAU + NVENC and is wrong for any
           other GPU. The portable parts (X11 libs, fontconfig, harfbuzz, awesome, rofi,
           dunst, picom, alacritty) are shared recipes and can be lifted as-is. The
           GPU-bound ones -- mesa, ffmpeg, mpv, libvdpau, vdpauinfo, nv-codec-headers,
           nvidia-470xx -- live in hosts/server/recipes/ precisely because they cannot
           be. Expect to write hosts/laptop/recipes/blfs-mesa.sh (Intel: gallium-drivers
           =iris/crocus; AMD: radeonsi) and laptop ffmpeg/mpv recipes with VAAPI rather
           than VDPAU.
  new      things `server` has no reason to build: a battery/backlight/suspend story,
           wireless firmware and tooling, and a display-brightness key path.
  keep     intel-microcode is per-CPU, not portable: check /proc/cpuinfo's `bugs:` line
           on this machine and write its own recipe if old_microcode shows up.

Give every new step the next unused seq. Do not renumber existing entries.
"""

from base import BASE, book, hand  # noqa: F401  (book/hand are for entries added below)

PACKAGES = BASE + [
]
