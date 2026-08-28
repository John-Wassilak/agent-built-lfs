# `server`

The machine this repo was written on, and the one it now runs on: LFS 13.0-systemd,
self-hosting. `host.toml`'s `[hardware]` has the current facts; `BUILD-REPORT.md` is the
full narrative, ~3,000 lines and appended to in date order.

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
- **Ten recipes live in `recipes/` here** rather than the shared tree, because they are
  bound to this GPU or this CPU: the NVIDIA driver, nv-codec-headers, libvdpau,
  vdpauinfo, intel-microcode, mesa (nouveau + glvnd), ffmpeg (NVENC/VDPAU), mpv (VDPAU),
  and the two `ch10-*` recipes generated from this host's overrides.
