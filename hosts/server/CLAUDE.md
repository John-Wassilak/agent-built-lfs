# `server`

The machine this repo was written on, and the one it now runs on: LFS/BLFS 13.1-systemd
(bumped from 13.0 2026-09-07 -- see `BUILD-REPORT.md`), self-hosting. `host.toml`'s
`[hardware]` has the current facts; `BUILD-REPORT.md` is the full narrative, ~3,000
lines and appended to in date order.

`BOOTSTRAP.md` is the deploy-time procedure -- currently the re-image that replaces this
live 13.0 root with the from-scratch 13.1 tree built in `hosts/server-rebuild/`. Read it
before touching the USB stick, `/dev/sdb`, or the overlay; nothing in `bin/` automates any
of it, and every disk identifier in it was re-confirmed against the live machine.

Things worth knowing before changing anything here:

- **This is a live system, not a tree.** `lfsbuild` detects `native` mode and runs steps
  against `/` as root. Chapters 04-07 are refused outright -- they build a temporary
  toolchain into a bare tree and would overwrite the running one. Chapter 08 onward is
  the supported upgrade path, one step at a time with `--only <step> --force`.
- **The desktop is X11 + awesome on the proprietary NVIDIA 470.xx driver, permanently.**
  That was an operator decision after Wayland proved a dead end on 470.xx (EGLStreams
  only). `HYPRLAND-PLAN.md` is the abandoned plan, kept because it explains the `seq` gaps
  in `packages.py`; `AWESOME-X11-PLAN.md` is what replaced it. Do not propose Wayland
  here.
- **The NVIDIA kernel modules are out-of-tree and proprietary.** Renaming or rebuilding
  the kernel orphans them until they are rebuilt against the new `/lib/modules/<ver>/`
  path. This has already caused one silent breakage.
- **`grub.cfg` is hand-written**, at `overlay/boot/grub.cfg`, and carries two things
  nothing else regenerates: the nouveau blacklist and
  `snd_hda_intel.probe_mask=0x1FF,0x1FF` (without which the BIOS misreports the codec
  slots and no audio hardware appears at all). Anything that rewrites grub.cfg must
  re-add both by hand.
- **Kernel config is `kernel-config.sh`**, which sources `bin/kernel-config-base.sh` and
  adds only this box's hardware: nouveau's DRM module and the HDA codecs. Generic options
  belong in the base, where the laptop gets them too.
- **Twelve recipes live in `hosts/server/recipes/` here** rather than the shared tree.
  Ten are bound to this GPU or this CPU: the NVIDIA driver, nv-codec-headers, libvdpau,
  vdpauinfo, intel-microcode, mesa (nouveau + glvnd), ffmpeg (NVENC/VDPAU), mpv (VDPAU),
  and the two `ch10-*` recipes generated from this host's overrides. Two more
  (`ch08-grub`, `ch10-grub`) were added 2026-09-07 during the LFS 13.1 bump: LFS 13.1
  added UEFI-target GRUB builds and boot-entry steps this host doesn't need (BIOS/MBR
  only) -- bound to this host's boot mode, not its GPU/CPU, but the same "device/boot
  path" test from root `CLAUDE.md` still puts them here.
- **A Windows 11 guest runs under qemu/KVM** (packages.py seq 268-273, 2026-10-21):
  qemu from the book, plus swtpm/libtpms as hand-authored recipes for the TPM 2.0 that
  Windows 11 needs. KVM and KVM_INTEL are in `kernel-config.sh`. The launcher is
  `overlay/usr/local/bin/win11-vm`, with images on `/mnt/big_drive/vm`. RDP reaches the
  guest only over wg0: qemu forwards `10.0.0.4:3389`, and the firewall accepts 3389 on
  wg0 alone (`blfs-overrides.json` page `blfs-iptables` block 2; the recipe is
  generated). USB devices pass through with `win11-vm usb-attach`. The CPU has no VT-d,
  so do not propose GPU or PCI passthrough. Since 2026-10-21/22: it runs as `win11vm`
  from `win11-vm@run`, its internet traffic leaves only through wg1
  (`win11vm-route`), its console is VNC on 10.0.0.4:5901, and `/mnt/big_drive/vm-share`
  is shared to it as `Z:` through virtiofsd (seq 274-275).
- **A Kali lab guest runs under the same qemu** (2026-10-22, no new packages):
  `overlay/usr/local/bin/kali-vm` and `kali-vm.service`, as `kalivm`, images on
  `/mnt/big_drive/kali` (read-only base plus an overlay; `kali-vm reset` starts over).
  NIC 1 is slirp NAT out enp6s0; NIC 2 is the tap `lab-kali` on `lab0`, the host-only
  bridge, 192.168.56.0/24, server .1, Kali pinned to .10 by MAC. lab0 and its taps are
  systemd-networkd files in `overlay/etc/systemd/network/50-lab*`, and a new lab target
  gets its own `50-lab-<name>.netdev`. The firewall routes nothing into or out of lab0 and
  lets it reach only DHCP on the host. Console: VNC on 10.0.0.4:5902, wg0 only.
  Since 2026-10-27 it also mounts `/mnt/big_drive/vm-share`, the same directory Windows
  sees as `Z:`, at `/mnt/share` (virtiofs, host ids squashed to `kali`).
  The lab tap runs on vhost-net (`VHOST_NET=m` in `kernel-config.sh`, 2026-10-27).
