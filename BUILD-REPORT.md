# LFS 13.0-systemd — build report

Built 2026-08-25 on Gentoo Hardened (gcc 15.3.0, binutils 2.46.1, glibc 2.43, kernel
6.18.35, 4 cores / 31 GB). Tree built at `/mnt/lfs`, harness at `/home/john/lfs`.

## Result

| | |
|---|---|
| Steps | **133 / 133 complete** |
| Build time | **8.36 h** across 139 step executions |
| Deliverable | `lfs-13.0-systemd-20260825.tar.gz` — 471 MB, 69,253 entries |
| SHA256 | `3c9dd694aa3449fff022dc0ffba4aecca29a0589ed29fdde04fc0e158dd4951b` |
| Tree size | 1.7 GB uncompressed |
| Manifests | 82 packages, 50,492 installed files tracked |

Verified in chroot: bash 5.3.0, gcc 15.2.0, glibc 2.43, systemd 259.1, perl 5.42.0,
Python 3.14.3. `ldd /usr/bin/bash` resolves all 6 libraries, nothing missing.

Kernel: `vmlinuz-6.18.10-lfs-13.0-systemd` (14 MB), plus `System.map-6.18.10` and
`config-6.18.10` in `/boot`.

## Slowest steps

```
ch08-gcc         226.0 min   (full test suite)
ch08-glibc        44.5 min   (full test suite)
ch06-gcc-pass2    21.4 min
ch05-gcc-pass1    18.0 min
ch10-kernel       13.8 min
```

## Test suites (critical three, as chosen)

| Package | Result | Verdict |
|---|---|---|
| glibc-2.43 | 3 FAIL, 4 XPASS, 0 ERROR | `io/tst-lchmod` is documented by the book as failing in the LFS chroot; `io/tst-faccessat-setuid` fails because we build as root in chroot; `malloc/tst-malloc-too-large-malloc-hugetlb2` depends on host hugepage config. |
| gcc-15.2.0 | ~475,000 expected passes, **15 unexpected failures** (gcc 11, libstdc++ 4, g++ 0) | Healthy. Ran as the unprivileged `tester` user per the book. |
| binutils-2.46.0 | 1 unique FAIL (`tmpdir/gp-gmon`, a gprofng test) | Normal. |

Full reports in `state/testreports/`. Seven non-critical suites (tcl, sed, openssl,
coreutils, gawk, findutils, make) also ran and passed before the policy was tightened —
no harm, just extra assurance.

## What the review caught

The recipes are extracted from the book automatically, but every disabled or rewritten
block is a recorded decision in `recipes/review-overrides.json` — **69 decisions across
26 recipes** (44 drop, 20 replace, 3 test, 1 enable, 1 defer). The ones that would have
produced a broken or wedged build:

- **27 mandatory `make install` commands silently disabled.** My first classifier keyed off
  surrounding prose ("test suite", "known to fail"). In the book the test-suite paragraph
  sits immediately *before* "Install the package: `make install`", so gcc's and binutils'
  installs inherited the hint and were dropped. Replaced with structural rules.
- **gcc-pass1 built without the in-tree GMP/MPFR/MPC the book requires** — proven by `cc1`
  linking against the host's `/usr/lib64/libmpfr.so.6`. Forced a full rebuild of Ch. 5–6.
- **Interactive commands that would hang an unattended build:** `su - lfs`, `passwd lfs`,
  `passwd root`, `tzselect`, `vim -c ':options'`, `make menuconfig`, `localectl` ×4,
  `timedatectl` ×4, `cp -i` ×3.
- **Literal placeholders that would have been written verbatim into config:** `/dev/<xxx>`
  in fstab, `<lfs>` in `/etc/hostname`, `<your name here>` in os-release,
  `<paper_size>` in groff, `<network-device-name>` in systemd-networkd,
  `<ll>_<CC>.<charmap>` in locale.conf, and a dangling
  `/usr/share/zoneinfo/<xxx>` symlink for `/etc/localtime`.
- **Diagnostic greps that exit 1 on the _good_ outcome** and so abort under `set -e`:
  glibc's `grep "Timed out"`, binutils' `grep '^FAIL:'`.
- **`ch08-stripping` aborting on non-ELF files.** The book's `find ... -name \*.so*` matches
  GNU ld linker scripts (`libc.so`, `libm.so`, `libgcc_s.so`) and, by glob accident,
  systemd `.socket` unit files. In the interactive shell the book assumes, `strip`'s
  "file format not recognized" is harmless stderr noise; under `set -e` it is fatal.
  Fixed by adding `|| true` to that one call, preserving the book's real behaviour.
- **Hardware-specific examples that would have been installed as real config:** udev rules
  hard-coded to a webcam (idProduct 1910) and TV tuner; a systemd override for a service
  literally named `foobar`; `KEYMAP=de-latin1`, which would have left a German keyboard.
- **`ch09-systemd-custom` block 4** would have *loosened* the coredump limit: its example
  `MaxUse=5G` is larger than systemd's default of 10% of the filesystem (~2.9 GB on a
  29 GB target). Dropped to keep the stricter default.

## Configuration chosen

- Timezone `America/Chicago` (matches host), locale `en_US.UTF-8`, keymap `us`, paper Letter
- Hardware clock **UTC** (no `/etc/adjtime`, so systemd assumes UTC)
- Hostname `lfs`; DHCP on any wired interface (`Name=en* eth*`); systemd-resolved stub
- `/tmp` on tmpfs (kept — reduces write wear on a USB target)
- Boot messages not cleared at boot (`TTYVTDisallocate=no`), useful on first boot

## Root password

Set non-interactively to **`lfs-changeme`**. The book uses interactive `passwd root`, which
cannot run unattended, and leaving the account locked would make the booted system
unusable. **Change it on first boot.**

## Deferred to the USB phase

- `grub-install` — no target device existed at build time. The grub *package* is installed
  and `/boot` is populated; only writing the bootloader to a disk remains.
- `/etc/fstab` uses `LABEL=LFSROOT` for `/` and `LABEL=LFSSWAP` for swap, so **label the
  partitions accordingly** when you create them (`mkfs.ext4 -L LFSROOT`,
  `mkswap -L LFSSWAP`). Nothing is bound to a device node.
- Kernel has the whole boot path built in (`=y`, no initramfs): ext4, SCSI disk, ATA/AHCI,
  NVMe, USB (xHCI/EHCI/OHCI/UHCI), usb-storage, UAS, devtmpfs, tmpfs. A gate in
  `bin/kernel-config.sh` fails the build if any of these ends up a module.
- Target is legacy BIOS, matching the book's GRUB chapter. A UEFI target would need the
  BLFS GRUB-EFI procedure instead.

## Harness

```
bin/extract-recipes.py   book HTML -> candidate recipes, applies review-overrides.json
bin/build-plan.py        ordered plan (book order), context + tarball per step
bin/lfsbuild             driver: logs, timing, resume, Ch.8 manifests, mount guards
bin/kernel-config.sh     scripted replacement for `make menuconfig`, with a boot-path gate
bin/lfs-archive          snapshot/deliverable tarball, mount guard + leak + preservation checks
bin/lfs-umount           unmount virtual kernel filesystems, deepest first
bin/fetch-sources.sh     download + md5-verify all 92 sources
```

`./bin/lfsbuild --status` shows state; `--list`, `--only`, `--from`, `--resume`,
`--dry-run` all work. Review decisions live in `recipes/review-overrides.json` so
re-extraction never loses them.

Snapshots: `after-ch06` (1.3 G), `after-ch07` (741 M), `after-ch08` (403 M).

## Archive flags, and why

`-p` is the load-bearing one: the tree has **17 setuid/setgid binaries** (`su`, `passwd`,
`ping`, `umount`, …) that are broken if mode bits are lost. Round-trip verified: `su`
extracts as `4755 root:root`. Hardlinks (3,562 files with link count > 1) are preserved —
2,439 link entries in the archive. `--xattrs`/`--acls` are kept for after BLFS but are
**not** load-bearing today: a by-the-book LFS 13.0 tree carries no file capabilities and no
`security.*` xattrs, which I verified with `getcap -r` and `getfattr` rather than assuming.

## Next

1. Partition and label the USB, `grub-install`, unpack the tarball, boot.
2. Change the root password.
3. BLFS plus maintenance tooling — a DESTDIR package manager seeded from the 82 Chapter 8
   manifests, and an advisory/version drift tracker against the LFS and BLFS books.
