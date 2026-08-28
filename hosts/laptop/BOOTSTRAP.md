# Bootstrapping `laptop`

Build path: **on the laptop itself, from a live host distro.** Chapters 4-11 run in a
chroot against a tree at `/mnt/lfs`, then the machine boots into LFS and everything after
that runs natively. This is the path `server` was built on and the one `lfsbuild`'s chroot
mode already supports; nothing new is needed to drive it.

## 0. Audit the hardware first

Nothing below is worth starting until `host.toml`'s `[hardware]` is filled in. Every TODO
there is an input to the kernel config or the package selection.

```
lscpu                          # model, cores/threads -> [hardware].cpu and build.jobs
grep -m1 bugs: /proc/cpuinfo   # old_microcode means an early-load microcode initrd
lspci -k                       # GPU, audio, storage controller, wireless + their drivers
lsblk -f                       # disks, filesystems, existing labels
lsusb                          # wireless/bluetooth that is on USB, not PCI
ls /sys/class/power_supply/    # battery and AC presence
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```

Two of these decide work that `server` never had to do: wireless almost certainly needs
firmware LFS does not ship (a BLFS step, not a kernel option), and UEFI changes the
Chapter 10 GRUB install.

Record the answers in `host.toml`, then start `BUILD-REPORT.md` with the audit output.
`server`'s report has the format.

## 1. Prepare the host distro

The live distro must satisfy the book's own prerequisites:

```
bash book/13.0/prologue/version-check.sh    # every line must pass
```

Then, as root on the host:

```
# partition and label -- the labels go in this host's ch10-fstab override, so pick them
# now and write them down
mkfs.ext4 -L LFSROOT /dev/<root-partition>
mkswap -L LFSSWAP /dev/<swap-partition>

export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 /dev/<root-partition> $LFS
/sbin/swapon -v /dev/<swap-partition>

mkdir -v $LFS/sources && chmod -v a+wt $LFS/sources
```

The `lfs` user and its environment come from `ch04-addinguser` and
`ch04-settingenvironment`, which `lfsbuild` runs as root on the host -- do not create
them by hand.

## 2. Sources

Either download them:

```
bin/fetch-sources.sh          # 92 tarballs into sources-staging/, md5-verified
mv sources-staging/* $LFS/sources/
```

or take them from `server`, which already has the LFS set and most of the BLFS set. Much
faster over a LAN, and the md5s are already verified there:

```
rsync -a --info=progress2 server:/sources/ $LFS/sources/
```

BLFS tarballs are fetched per package later; `blfs-staging/blfs-md5` on `server` records
what it used.

## 3. Host-specific config, before the build reaches it

Three files must exist before the steps that consume them:

- **`review-overrides.json`** in this directory, with a `ch10-fstab` block 0 carrying the
  labels chosen in step 1, and a `ch10-kernel` block naming this machine's `/boot` paths.
  Copy the shape from `hosts/server/review-overrides.json`. Then
  `bin/extract-recipes.py --host laptop` writes `hosts/laptop/recipes/ch10-*.sh`.
- **`kernel-config.sh`** -- work through its four TODOs from the audit. It exits 1 until
  then, on purpose.
- **`overlay/boot/grub.cfg`** for after first boot. Hand-written, like `server`'s.

## 4. Build chapters 4-11

```
bin/extract-recipes.py --host laptop --check    # expect zero drift
bin/extract-recipes.py --host laptop
bin/build-plan.py      --host laptop
bin/lfsbuild --host laptop --chroot --status    # 0/133, next = ch04-creatingminlayout
bin/lfsbuild --host laptop --chroot --resume
```

`--resume` runs everything not yet completed and stops on the first failure, with the log
in `hosts/laptop/logs/<step>.log`. Chapter 10 needs `kernel-config.sh` and
`kernel-config-base.sh` staged into `$LFS/sources` together -- the host script sources the
base by relative path.

Before rebooting: set a root password inside the chroot, and check `/etc/fstab` matches
the labels actually on disk. A wrong label here is an unbootable system with no rescue
path except the live distro.

## 5. First boot, then everything else natively

After the reboot, `lfsbuild` detects `native` mode by itself (`ID=lfs` in
`/etc/os-release`, no populated tree at `/mnt/lfs`) and refuses chapters 04-07, which is
correct -- they would overwrite the running toolchain.

```
bin/extract-blfs.py --host laptop --check
bin/extract-blfs.py --host laptop
bin/lfsbuild --host laptop --blfs --resume
```

`packages.py` is `BASE` alone at this point: 16 steps to a machine with a CA store, ssh,
git, sudo, a firewall, and Node.js for Claude Code. Get there and confirm it before
planning a desktop.

## 6. Then the desktop, deliberately

`server`'s 202 additional steps are not a template. Take the portable ones from the shared
`recipes/` tree and write this machine's own for anything GPU-bound -- at minimum
`blfs-mesa.sh` with the right `gallium-drivers`, and ffmpeg/mpv with VAAPI rather than
VDPAU. `packages.py`'s header lists what transfers and what does not.

Add laptop-only work `server` has no equivalent of: battery and lid handling, backlight
keys, suspend/resume, touchpad configuration, and the wireless firmware from step 0.
