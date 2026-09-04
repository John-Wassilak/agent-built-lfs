# Bootstrapping `laptop`

**Status: done.** Steps 0-5 below ran to completion and step 5's deploy landed
2026-09-03 (`17c4112`, "deploy to nvme0n1p1") -- this machine's root is real LFS now
(`/etc/os-release` reads `ID=lfs`), not the Gentoo it started from. Step 6 is where
things actually are: still native, still ongoing, `host.toml`'s `build.mode = "native"`
now pins that explicitly rather than relying on auto-detection. The pre-deploy chroot
tree steps 1-5 describe building under `/mnt/crypt` is gone -- it went stale once the
deploy above superseded it, and was removed 2026-09-04 after confusing `lfsbuild`'s mode
detection for a session (see `CLAUDE.md` and `BUILD-REPORT.md`'s 2026-09-04 entries).
Kept below verbatim as the real record of how this machine got built, not as a procedure
to re-run.

Build path, revised 2026-08-28 after the hardware audit and disk-space reality (see
`BUILD-REPORT.md`): **chroot build in a directory inside this repo checkout, not a
dedicated partition, because there is no unpartitioned space on this disk.** Chapters
4-11 run in that chroot, then the finished tree is archived with `bin/lfs-archive
--tree --final` and deployed to the real root partition (`nvme0n1p1`, reformatted) from
USB rescue media -- the same restore procedure `bin/lfs-archive` prints for a `--live`
backup, reused here for a `--tree` image. Only after that reboot does anything run
natively. `lfsbuild`'s chroot mode needs no changes to support any of this -- the chroot
tree is just a directory, not necessarily its own mounted filesystem.

Target desktop from the start: **Hyprland / Wayland / pipewire**, not X11 -- decided
2026-08-28, unlike `server` where Wayland was a dead end on Kepler-generation NVIDIA.
This machine's Intel HD 520 has a fully open, current driver, so nothing here fights the
hardware the way it would have on `server`.

## 0. Hardware audit -- done, 2026-08-28

See `BUILD-REPORT.md`'s "baseline hardware audit" section for the full output and
`host.toml`'s `[hardware]` table for the resolved facts. `kernel-config.sh` is filled in
from it and no longer a stub.

The one thing the audit could not resolve, because it depends on decisions rather than
hardware: **disk space.** The 238.5G NVMe is fully partitioned (50G root, 16G swap,
172.5G LUKS `/mnt/crypt`, this repo's own location) with only 6-7G free on the two
volumes that have any room at all, and no unpartitioned space. Operator decision:
build in-repo, watch free space by hand while building, get as much of LFS+BLFS as fits,
archive, deploy from USB. Not: repartition, or add external storage.

## 1. Prepare the host distro

The live distro must satisfy the book's own prerequisites:

```
bash book/13.0/prologue/version-check.sh    # every line must pass
```

No partitioning or mounting needed for the chroot tree itself -- `host.toml`'s
`chroot_tree` points inside this repo checkout, and `lfsbuild --chroot` treats it as a
plain directory:

```
mkdir -pv /mnt/crypt/john/projects/agent-built-lfs/lfs
mkdir -v  /mnt/crypt/john/projects/agent-built-lfs/lfs/sources
chmod -v a+wt /mnt/crypt/john/projects/agent-built-lfs/lfs/sources
df -h /mnt/crypt   # check free space before every session, not just the first
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

## 3. Host-specific config -- mostly done

- **`review-overrides.json`** -- `ch10-fstab` block 0 is filled in (`LABEL=LFSROOT` /
  `LABEL=LFSSWAP`, matching the deploy target's existing partitions). `ch10-kernel`'s
  `/boot` version-string blocks are still open: fill them in with the actual kernel
  version once Chapter 10 is reached, then run `bin/extract-recipes.py --host laptop` to
  write `hosts/laptop/recipes/ch10-*.sh`.
- **`kernel-config.sh`** -- done, see `BUILD-REPORT.md`'s audit section for what each
  addition is for.
- **`overlay/boot/grub.cfg`** -- still needed, hand-written like `server`'s, but only
  relevant at deploy time (step 5) since this box boots BIOS/MBR onto the existing
  partition table, not a fresh install.

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
base by relative path. `build.jobs` is capped at 2 in `host.toml` (not the machine's full
4 threads) -- this is the daily driver, and the operator wants headroom to keep using it
while a build runs.

Set a root password inside the chroot before archiving.

## 5. Get as much BLFS built as fits, then archive and deploy

Continue into BLFS the same way (`bin/extract-blfs.py --host laptop`, `bin/lfsbuild
--host laptop --blfs --chroot --resume`), watching `df -h` on `/mnt/crypt` between
packages -- there is no slack here to run out of space mid-build and recover cleanly.
`packages.py` starts at `BASE` (16 steps: CA store, ssh, git, sudo, curl/wget, a
firewall, Node.js for Claude Code) and grows from there with the Hyprland/Wayland/
pipewire tiers, researched just-in-time against `book/blfs-13.0/` the same way `server`'s
`HYPRLAND-PLAN.md` was -- not written speculatively ahead of the real book text. Expect
the same shape server found: most of the Wayland/GPU/input stack has real BLFS pages,
the Hyprland ecosystem itself does not and gets built from Arch's `extra` PKGBUILDs as
the sourcing reference, same policy as server.

When there's nothing more that comfortably fits:

```
bin/lfs-archive --tree --final /mnt/crypt/john/projects/agent-built-lfs/laptop-lfs.tar.zst
```

Then, from USB rescue media, booted on the laptop itself:

The `-O` exclusions matter: this host's `mke2fs.conf` enables `metadata_csum`,
`metadata_csum_seed`, and `orphan_file` by default for `ext4`, but `grub-2.14`'s
`fs/ext2.c` (checked directly against `lfs/sources/grub-2.14.tar.xz`) never references
any of the three -- no rejection, no support. Left on, GRUB misreads the extent tree of
any file too large to stay inline in the inode and reports it "truncated" partway
through loading -- hit on the USB stick's own deploy, see `BUILD-REPORT.md`'s
2026-09-02 entry.

```
mkfs.ext4 -L LFSROOT -O ^metadata_csum,^metadata_csum_seed,^orphan_file /dev/nvme0n1p1  # the CURRENT Gentoo root -- confirm before running
mkswap    -L LFSSWAP /dev/nvme0n1p2
mount /dev/nvme0n1p1 /mnt/target
tar --extract --file laptop-lfs.tar.zst -p --numeric-owner --xattrs --acls \
    --same-owner -C /mnt/target
```

Then reinstall GRUB into `/dev/nvme0n1` (BIOS/MBR, matching the operator's decision to
keep legacy boot rather than switch to UEFI/GPT) from within the restored tree, chrooted
from the rescue media. `nvme0n1p3` (the LUKS `/mnt/crypt` volume, this repo's own home)
is untouched by any of this -- only p1 and p2 are reformatted.

## 6. First native boot, then everything else natively

After the reboot, `lfsbuild` detects `native` mode by itself (`ID=lfs` in
`/etc/os-release`, no populated tree at the chroot path) and refuses chapters 04-07,
which is correct -- they would overwrite the running toolchain. Resume BLFS from here
with `bin/lfsbuild --host laptop --blfs --resume` (no `--chroot`), continuing whatever
tiers didn't fit before the archive step.
