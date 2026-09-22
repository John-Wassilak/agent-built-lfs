# Bootstrapping `server`

**Status: imaged 2026-09-21, not yet booted.** Steps 1-5 ran to completion that day
(`BUILD-REPORT.md` has the narrative and the measurements); step 6, first boot and the
bookkeeping that follows it, is what remains. The text below is the procedure, corrected
in three places by having been run.

Unlike `laptop`'s, this was not a from-nothing bootstrap -- `server` has been a live LFS
machine since 2026-08-25. It is a *re-image*: the running, incrementally-grown 13.0 root
replaced by the from-scratch 13.1 tree built in `hosts/server-rebuild/`, done via a
bootable USB because you cannot overwrite `/` while it is mounted as `/`.

The original 2026-08-25 bootstrap (build to a tree, tar it, USB, extract onto `/dev/sdb`)
is recorded in `BUILD-REPORT.md` under "USB deployment" and "Permanent-drive deployment".
That is history, not this procedure. This one differs on one point that changes
everything downstream: **the USB is itself a bootable copy of the new system**, not a
rescue stick carrying a tarball. You boot into 13.1 from the stick, then push it onto the
target disk from there.

Read root `CLAUDE.md` and `hosts/server/CLAUDE.md` first. Nothing in `bin/` automates any
of this -- deploy-time steps are manual by design.

## The hardware, resolved

Confirmed 2026-09-21 on the live machine (`lsblk`, `fdisk -l`, `blkid`). Every identifier
below is real; do not copy one from `laptop`'s doc or from an older `BUILD-REPORT.md`
section, because both carry different disks.

| | |
|---|---|
| `/dev/sda` | 465.8G. `sda1` swap, `sda2` ext4 `/mnt/big_drive`. **Not part of the LFS install. Never touched by any step here.** |
| `/dev/sdb` | 149.1G, the deploy target. `sdb1` = 16G swap `LFSSWAP`, PARTUUID `c2cd0612-01`. `sdb2` = 133G ext4 `LFSROOT`, PARTUUID `c2cd0612-02`, fs-UUID `4ed155bc-b1da-4117-9f92-9c952e807880`. Currently the live 13.0 root. |
| `/dev/sdc` | 14.6G USB, the deploy stick. Single partition `sdc1`, ext4 `LFSUSB`, PARTUUID `57b53ab2-01`, fs-UUID `62477792-3f7e-46e7-8104-775f9c7d41a7`, boot flag set, MBR sig `0x57b53ab2`. |

Boot mode is **legacy BIOS/MBR**, not UEFI -- an operator decision carried from the
original build. `hosts/server/recipes/ch08-grub.sh` and `ch10-grub.sh` exist to strip LFS
13.1's UEFI-target steps for exactly this reason. A UEFI target would need the BLFS
GRUB-EFI procedure and a different partition table.

**Device nodes move.** `sdc` is the stick only while the current disks are attached in
the current order. Re-confirm with `lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTUUID` before
any `mkfs`, `dd` or `grub-install`, and match on the label, not the letter.

## What gets deployed

- **The tree**: `/mnt/lfs`, the `server-rebuild` chroot build. LFS 134/134 + BLFS 221/221,
  finished 2026-09-09. It lives on the live 13.0 root, so it disappears when `sdb2` is
  re-imaged -- the USB copy is what survives that, and is what the restore reads from.
- **The completion record**: `hosts/server-rebuild/state/completed`. Once the new image
  boots as the real `server`, this becomes the live record and
  `hosts/server/state/completed` gets archived as history for the 13.0 image it describes.
  `hosts/server-rebuild/host.toml` already says so in its own header.
- **The overlay**: `overlay/` (shared) and `hosts/server/overlay/` (this machine).
  Thirteen files, none of them applied by any tool -- see "Apply the overlay" below.

## Known open items -- settle these before deploying

- **`/etc/os-release` and `/etc/lsb-release` in the *existing* built tree say 13.0.**
  Fixed at the source 2026-09-21, but the fix is in the override, not in the tree: the
  shared `ch11-theend` blocks stored a whole command and so froze the version string the
  book printed when they were recorded. `hosts/server/review-overrides.json` now carries a
  host override with the 13.1 strings, and `hosts/server/recipes/ch11-theend.sh` is
  generated from it. **The already-built `/mnt/lfs` tree still has the wrong files**,
  because the recipe ran months before the override was corrected. Either re-run that one
  step against the tree, or just write the two files by hand during step 5's fixups --
  they are four lines and seven lines of `cat > … << EOF`. Check with
  `grep VERSION= /mnt/target/etc/os-release` before rebooting. `/etc/lfs-release` was
  always correct; it is the one block nothing overrode.
- **Hostname is `lfs`, not `server`.** Inherited from the book's own default via
  `ch09-network`. Harmless but confusing on a network that already has a `server`; set
  `/etc/hostname` on the target during the post-restore fixups if you want it changed.
- **The overlay has never been applied to this tree.** `BUILD-REPORT.md`'s 2026-09-09
  entry says so outright. Without it there is no `/boot/grub/grub.cfg` on the target, no
  `xorg.conf`, no `sshd_config`, none of the awesome/alacritty/mpv/picom dotfiles, and
  none of the three units in `overlay/units/`.

## 1. Prepare or refresh the USB

Skip to step 2 if the existing stick is current -- as of 2026-09-21 it is, and boots after
the fixes in that day's `BUILD-REPORT.md` entry. This section is how to rebuild it.

Format, from the live system, with the feature exclusions:

```sh
mkfs.ext4 -L LFSUSB -O ^metadata_csum,^metadata_csum_seed,^orphan_file /dev/sdc1
```

The `-O` exclusions are load-bearing and easy to lose, because `mke2fs.conf` enables all
three by default and `grub-2.14`'s `grub-core/fs/ext2.c` neither supports nor rejects any
of them. GRUB then misreads the extent tree of any file too large to stay inline in the
inode -- `grub.cfg` loads, the kernel does not, and the error is
`error: file '/boot/vmlinuz-…' is truncated`. This cost `laptop` a boot on 2026-09-03;
`hosts/laptop/BUILD-REPORT.md` has the diagnosis down to the bitmask. The current stick
happens to survive without the exclusions only because its kernel landed in 2 extents,
inside the 4 inline slots -- a more fragmented copy would not, so do not take the current
stick as evidence the flags are optional.

Populate it:

```sh
mount /dev/sdc1 /mnt/usb
rsync -aHAX --numeric-ids --info=progress2 \
      --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' \
      --exclude='/tmp/*' --exclude='/root/.cache/*' \
      /mnt/lfs/ /mnt/usb/
```

The virtual-filesystem exclusions are not optional. A first attempt without them tried to
copy `/proc/kcore` -- a pseudo-file the size of RAM -- and filled the disk.

Then the deploy payload, so the booted stick can do the restore without a network:

```sh
mkdir -p /mnt/usb/root/deploy
rsync -a /home/john/agent-built-lfs /mnt/usb/root/deploy/      # repo, full git history
rsync -a <claude npm global prefix>  /mnt/usb/root/deploy/claude-npm-global
```

Install the bootloader from inside a chroot on the stick, so it is the target's own GRUB
writing the target's own disk rather than the host's:

```sh
mount --bind /dev  /mnt/usb/dev   ; mount --bind /dev/pts /mnt/usb/dev/pts
mount -t proc proc /mnt/usb/proc  ; mount -t sysfs sysfs  /mnt/usb/sys
chroot /mnt/usb /usr/bin/env -i HOME=/root TERM="$TERM" PATH=/usr/bin:/usr/sbin /bin/bash --login
  grub-install --target=i386-pc --recheck /dev/sdc
```

Write the stick's `grub.cfg` and `fstab` per step 2's two rules, then
`umount -R /mnt/usb` and `e2fsck -f -n /dev/sdc1` before pulling it.

Expect all of this to run long. The flash is the bottleneck, not the bus: roughly
1.1 MB/s on small files. `grub-install` can sit in uninterruptible sleep for ten minutes
behind the kernel's write-back queue after a large extract -- check `/proc/meminfo`'s
`Dirty` line before assuming it hung.

## 2. The two rules that decide whether the stick boots

Both were violated on the first attempt and both are fixed on the current stick. The
comment blocks in the stick's own `/boot/grub/grub.cfg` and `/etc/fstab` restate them;
`BUILD-REPORT.md`'s 2026-09-21 entry has the full diagnosis.

- **`root=PARTUUID=`, never `root=UUID=`.** There is no initramfs on this system --
  `/boot/microcode.img` is microcode only, one cpio entry. The kernel's `name_to_dev_t`
  resolves `PARTUUID=`, `PARTLABEL=`, a `/dev` node or `maj:min`; resolving a *filesystem*
  UUID is udev's job and needs an initramfs. A `root=UUID=` line reaches the kernel as an
  unparseable string and it panics with `VFS: Unable to mount root fs on unknown-block(0,0)`.
  For the stick that is `root=PARTUUID=57b53ab2-01`. GRUB's own `search --set=root
  --fs-uuid` line is a different thing and a *filesystem* UUID there is correct -- GRUB
  can read ext4, the kernel at that stage cannot.
- **`rootwait` on the stick, and only on the stick.** USB enumeration is slower than the
  kernel's root probe, so a correct `root=` can still be looked up before `usb-storage`
  has registered `sdX`. `server`'s internal-SATA `grub.cfg` genuinely does not need it,
  which is exactly how it went missing -- the stick's config was adapted from that one.

And the matching trap one layer up:

- **The stick's `/etc/fstab` must point at the stick.** As rsync'd it reads
  `LABEL=LFSROOT / ext4 defaults 1 1`, which on this machine resolves to `/dev/sdb2` --
  the disk the stick exists to re-image. systemd's fstab-generator would fsck that device
  and mount it as `/` over the real root; with `sdb` wiped it blocks the boot on a device
  that does not exist. Same for `LABEL=LFSSWAP` (`sdb1`, and the stick has no swap of its
  own). Use `PARTUUID=57b53ab2-01` for `/` and drop the swap line -- then put the `LABEL=`
  form back on the target in step 5, or the restored system inherits the stick's identity.

## 3. Boot the stick

BIOS boot order to USB. You should get a 5-second single-entry GRUB menu, then a text
console. The stick's `gfxpayload` is `text` by design -- no X, no NVIDIA module loading,
nothing that depends on the GPU being in a known state.

Logging in:

- `root` and `john` both have real password hashes in the tree (`john` is uid 1000,
  `/etc/sudoers.d/00-sudo` present). Root is **not** locked here, unlike the live 13.0
  system where it was locked on 2026-08-26 in favor of `john` plus sudo. The root password
  was set during USB prep to a value recorded outside this repo; if you no longer have it,
  chroot into the stick from the live system and reset it before rebooting.
- **Networking and SSH come up on their own.** `systemd-networkd` DHCPs on `en*`/`eth*`
  (`/etc/systemd/network/10-dhcp.network`), `sshd.service` is enabled, and
  `/etc/systemd/scripts/iptables` -- default-DROP on INPUT -- explicitly accepts
  `tcp/22 NEW`. So you can drive the restore over SSH from `laptop` rather than through
  the console, which is the point of enabling it.
- **sshd generates fresh host keys on first start** (`ExecStartPre=ssh-keygen -A`); the
  tree ships none. `laptop`'s `known_hosts` will object. Expect that, and verify the
  fingerprint at the console rather than blindly removing the entry.
- `default.target` is `multi-user.target`. This was set during USB prep and had never
  existed on the live system either.

Confirm you are on the stick before touching anything: `findmnt -no SOURCE /` must say
`/dev/sdc1`, and `uname -r` must say `7.1.8-lfs-13.1-systemd`.

## 4. Re-image the target

`/dev/sdb2` is the live 13.0 root and is about to be destroyed. Nothing on it is backed up
by this procedure. `/mnt/lfs` -- the built tree -- lives on that partition too, and the
stick is its only other copy. `/dev/sda` is not involved.

Reuse the existing geometry; it already matches (`sdb1` 16G swap, `sdb2` 133G root), so
there is no repartition step and the PARTUUIDs stay `c2cd0612-01`/`-02`.

```sh
mkfs.ext4 -L LFSROOT -O ^metadata_csum,^metadata_csum_seed,^orphan_file /dev/sdb2
mkswap    -L LFSSWAP /dev/sdb1
mkdir -p /mnt/target && mount /dev/sdb2 /mnt/target
rsync -aHAX --numeric-ids --delete --info=progress2 \
      --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' \
      --exclude='/tmp/*' --exclude='/mnt/*' --exclude='/root/deploy/*' \
      / /mnt/target/
```

The `-O` exclusions apply here for the same GRUB reason as the stick. `--exclude=/mnt/*`
keeps the target's own mountpoint out of its own copy. `--exclude=/root/deploy/*` leaves
the deploy payload on the stick where it belongs.

**But that leaves the target with no repo at all, and no home.** The sentence this
replaces said the repo "comes across with `/home`" -- it does not. The stick was
populated from `/mnt/lfs`, the fresh chroot build, whose `/home/john` is the eight
skeleton dotfiles `ch08-shadow` created and nothing else. `john`'s real home, the repo
among it, only ever existed on the 13.0 root this step reformats. So either copy it off
before the wipe (2026-09-21 did: `/mnt/big_disk/backups/home-john-<date>/`, an rsync
`--link-dest` snapshot against the previous backup, so only the delta is written), or
accept a bare `/home/john` and re-clone the repo from GitHub afterwards.

Note that `mkfs.ext4` just generated a new fs-UUID (`blkid /dev/sdb2`): it will **not**
be `4ed155bc-…` any more, and the disk table at the top of this file still records the
old one. Step 5's `grub.cfg` does **not** need it -- that file searches by `--label
LFSROOT`, which step 4's `mkfs.ext4 -L LFSROOT` writes back every time, precisely so this
procedure stops minting an identifier the boot path then has to be hand-edited to match.

## 5. Fix up the target before rebooting

In order, all against `/mnt/target`:

1. **`/etc/fstab`** back to the target's identity -- undo the stick-specific lines:

       LABEL=LFSROOT   /      ext4   defaults   1  1
       LABEL=LFSSWAP   swap   swap   pri=1      0  0
       UUID=ca21e228-7677-4ab3-ba4b-ddf066164c80  /mnt/big_drive  ext4  defaults  0  2

   The labels were just written by step 4's `mkfs`/`mkswap`, so this needs no device node.
   The third line is not stick-specific and is easy to lose: it is the 13.0 root's own
   entry for `sda2`, the data disk, and nothing else mounts it -- `host.toml`'s
   `[hardware] data` records it but no tool reads that. Copy it from the old root's
   `/etc/fstab` before the wipe, or from
   `/mnt/big_disk/backups/lfs-13.0-final-20260921/etc-var-lfsmaint.tar.zst` after.
2. **Apply the overlay.** Nothing does this for you. `overlay/` first, then
   `hosts/server/overlay/` on top -- host wins on any collision, which is the whole point
   of the split. `overlay/units/*` (`cpufreq-governor.service`,
   `lfsmaint-check.service`/`.timer`) go to `/etc/systemd/system/` and need explicit
   `systemctl enable`; the `cpufreq` one is not cosmetic, it is the fix for the measured
   2.1x loss from the default governor. `hosts/server/overlay/home/john/*` are `john`'s
   dotfiles and must land owned by uid 1000, not root.
3. **`/boot/grub/grub.cfg`** is copied from `hosts/server/overlay/boot/grub.cfg`
   **verbatim** -- no hand-edited identifiers. It searches `--label LFSROOT` and boots
   `root=PARTUUID=c2cd0612-02`, and both survive this procedure: step 4's
   `mkfs.ext4 -L LFSROOT`/`mkswap -L LFSSWAP` write the labels back and the partition
   table is never touched. This step used to say to
   patch `search --set=root --fs-uuid` to the new fs-UUID by hand; that is what was
   missed on 2026-09-21, leaving a `search` that matched nothing on the machine for
   every boot after the re-image (it booted only because a failed `search` leaves `$root`
   at the partition GRUB loaded from). An identifier a human has to remember to update
   is the defect, so there is no longer one to update. Do **not** add `rootwait` here --
   that is the stick's line.
   `hosts/server/CLAUDE.md` is emphatic about the two things this file carries that
   nothing regenerates: the `modprobe.blacklist=nouveau` and
   `snd_hda_intel.probe_mask=0x1FF,0x1FF`. Without the second there is no audio hardware
   at all, because the BIOS misreports the codec slots. Verify with `grub-script-check`.
4. **`grub-install --target=i386-pc --recheck /dev/sdb`**, from a chroot on
   `/mnt/target`, same bind-mount dance as step 1. A filesystem copy carries `/boot` but
   not the MBR; the disk does not boot until this runs.
5. **Optional identity**: `/etc/hostname` (currently `lfs`), and
   `truncate -s 0 /mnt/target/etc/machine-id` if you would rather the target not share the
   stick's `621d52cd…` -- systemd regenerates it on first boot and it is the DHCP DUID
   seed.

Then `umount -R /mnt/target`, `e2fsck -f -n /dev/sdb2`, pull the stick, reboot.

## 6. First boot, and the bookkeeping

Verify in roughly this order -- the point is to catch a bad deploy before building
anything on top of it:

```sh
findmnt -no SOURCE /            # /dev/sdb2, not sdc1
uname -r                        # 7.1.8-lfs-13.1-systemd
cat /etc/os-release             # 13.1-systemd, if the open item above was settled
systemctl is-system-running     # running
systemctl --failed              # empty
lsmod | grep nvidia             # out-of-tree, rebuilt against 7.1.8 -- see below
lfsmaint report                 # package database survived the copy
```

**The NVIDIA modules are the thing most likely to be wrong.** They are proprietary and
out-of-tree, they are not part of the in-tree kernel build, and a kernel change orphans
them until rebuilt against the new `/lib/modules/<ver>/` path. This has already caused one
silent breakage on this machine. If X does not come up, check that first, not `xorg.conf`.

Then the state move, which is what makes the repo describe reality again. **Do not defer
this.** On the 2026-09-21 deploy it was the one item of the four below that did not get
done, and it stayed undone through three subsequent sessions because every symptom it
produced looked like an isolated stale version string. `--host server` kept resolving the
*13.0* install's manifests and completion record onto a 13.1 machine, and `lfsmaint` was
only correct because the database had been rebuilt by hand with an explicit
`--manifests hosts/server-rebuild/manifests`. It also hid two packages that the re-image
dropped. Done for this deploy on 2026-09-21, late; see `hosts/server/archive/README.md`.

- `hosts/server-rebuild/state/completed`, `timings.tsv`, `manifests/` and `logs/` become
  `hosts/server/`'s. These are the records of the tree that was actually deployed.
- The old `hosts/server/` copies are archived as the outgoing image's history rather than
  deleted -- they are the record of a real build, just not of the running one.
- **Diff the two `completed` files before moving.** Anything present in the outgoing
  system's record but absent from the deployed tree's was built natively on the old root
  and is simply *gone* after the re-image. On this deploy that was `blfs-unixodbc` (95
  files) and `slfs-htop` (7), both added after the rebuild chroot had finished. Check
  each against the live root rather than assuming: `ch08-intltool` and `ch08-xml-parser`
  came up in the same diff and are correct absences, because LFS 13.1 dropped both pages.
- `hosts/server/host.toml`'s `[hardware] kernel` still reads `6.18.10`; update it, along
  with the root/boot lines if anything about the disks changed.
- Append the deploy to `BUILD-REPORT.md` with the date, per root `CLAUDE.md`. What broke
  and what you measured, not just that it worked.

Run `bin/extract-recipes.py --check` and `bin/extract-blfs.py --check` once natively.
Zero drift is the expected state, and it is the cheapest evidence that the tree you are
now running still matches the record that produced it.

## If it does not boot

Match the symptom to the layer -- the two failure modes look similar and are fixed in
completely different places.

- **GRUB menu never appears**: the bootloader was not written, or was written to the wrong
  disk. `grub-install` again from a chroot, against the disk, not the partition.
- **`error: file '…' is truncated` at the GRUB menu**: the ext4 feature bug. The
  filesystem needs reformatting with the `-O ^…` exclusions and repopulating. No config
  edit fixes this.
- **`error: no such device` / `unknown filesystem`**: the `search --fs-uuid` line does not
  match the filesystem it is on. One-line fix.
- **Kernel loads, then `VFS: Unable to mount root fs on unknown-block(0,0)`**: `root=` is
  wrong -- wrong PARTUUID, or a `UUID=`/`LABEL=` form the kernel cannot resolve without an
  initramfs. On removable media, also suspect a missing `rootwait`. One-line fix.
- **Boot proceeds, then hangs or fails mounting `/` or a dependency of it**: `/etc/fstab`
  names a device that is absent, or the wrong one. Check what its labels actually resolve
  to on the machine as booted, not as built.

GRUB has a full shell at `c`. `ls`, `ls (hd0,msdos2)/boot`, and `search --fs-uuid` there
will tell you what GRUB can actually see, which is usually the fastest way to decide which
of the above you are looking at.
