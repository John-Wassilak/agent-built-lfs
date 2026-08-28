# What the first build taught

Extracted from `hosts/server/BUILD-REPORT.md` because none of it is about `server`. The
report keeps the narrative and the measurements; this is the part that applies to any
machine built from this repo.

## Extracted recipes are candidates, not instructions

The book is written for a human at a prompt. Automatic extraction produces something that
looks runnable and is not. Every disabled or rewritten block is a recorded decision with
a reason citing the book -- 80 for LFS and 19 for BLFS on the first machine, across 34
recipes.

The classes of failure that review catches, all of which will recur on a new machine:

- **Interactive commands that hang an unattended build.** `su - lfs`, `passwd`, `tzselect`,
  `vim -c ':options'`, `make menuconfig`, `localectl` ×4, `timedatectl` ×4, `cp -i` ×3.
- **`exec` blocks that silently truncate the rest of the recipe.** `ch07-createfiles`
  block 5 is `exec /usr/bin/bash --login` -- the book telling a reader to restart their
  shell. As a script line it *replaces* the shell, so the following block, which creates
  `/var/log/{btmp,lastlog,faillog,wtmp}`, never ran and nothing reported it. The same
  truncation in `ch08-bash` discarded that package's manifest and left its source tree
  behind. Both blocks are dropped by decision now, but the pattern is the lesson: an
  `exec` in an extracted recipe is a silent partial run, not an error.
- **Literal placeholders written verbatim into real config.** `/dev/<xxx>` in fstab,
  `<lfs>` in `/etc/hostname`, `<your name here>` in os-release, `<paper_size>` in groff,
  `<network-device-name>` in systemd-networkd, `<ll>_<CC>.<charmap>` in locale.conf, and a
  dangling `/usr/share/zoneinfo/<xxx>` symlink for `/etc/localtime`.
- **Diagnostic greps that exit 1 on the good outcome** and so abort under `set -e`:
  glibc's `grep "Timed out"`, binutils' `grep '^FAIL:'`.
- **Globs that catch non-targets.** `ch08-stripping`'s `find ... -name \*.so*` matches GNU
  ld linker scripts (`libc.so`, `libm.so`, `libgcc_s.so`) and, by glob accident, systemd
  `.socket` units. Harmless stderr noise in the shell the book assumes; fatal under
  `set -e`. Fixed with `|| true` on that one call, preserving the book's behaviour.
- **Hardware-specific examples installed as real config.** udev rules hard-coded to a
  particular webcam and TV tuner, a systemd override for a service literally named
  `foobar`, `KEYMAP=de-latin1`.
- **Examples that loosen a default.** `ch09-systemd-custom` block 4's `MaxUse=5G` coredump
  limit is larger than systemd's own default of 10% of the filesystem.

Two classifier lessons, both from real breakage:

- Keying "is this optional?" off surrounding prose fails, because the book's test-suite
  paragraph sits immediately before "Install the package: `make install`". That dropped
  27 mandatory installs, gcc's and binutils' included. Structural rules only.
- `\btest\b` does not match `make tests`, so a test suite stayed enabled and failed.
  The regex is `\btests?\b`.

And one that only a build proves: gcc-pass1 built against the *host's* MPFR rather than
the in-tree GMP/MPFR/MPC the book requires, visible as `cc1` linking
`/usr/lib64/libmpfr.so.6`. Chapters 5-6 had to be rebuilt. Check what the toolchain
actually linked against, do not infer it from the configure line.

## Archive flags that are load-bearing

`lfs-archive`'s tar flags are not decoration:

- `-p` is the critical one. The tree has 17 setuid/setgid binaries (`su`, `passwd`,
  `ping`, `umount`, …) that are broken if mode bits are masked by the caller's umask.
  Verified by round-trip: `su` extracts as `4755 root:root`.
- `--numeric-owner`, because the LFS uid/gid map is its own, not the restoring host's.
- `--sparse`, because several installed files are sparse.
- Hardlinks are preserved by default and matter: 3,562 files with link count > 1 on the
  first machine, 2,439 link entries in the archive.
- `--xattrs`/`--acls` are kept but are **not** load-bearing on a by-the-book LFS 13.0
  tree: zero file capabilities and zero `security.*` xattrs, checked with `getcap -r` and
  `getfattr` rather than assumed. Kept so the command stays correct if that changes.
- `--one-file-system` in live mode is the primary guard. It stops at every mount
  boundary, so `/proc`, `/sys`, `/dev`, `/run`, `/tmp` and any mounted data disk are
  excluded structurally rather than by a pattern someone must remember to update. The
  mount points are still archived as empty directories, which is what a restore needs.

Tree mode refuses to run while the virtual kernel filesystems are bound into the tree:
archiving the host's `/proc` and `/dev` produces an image that only reveals its
corruption at boot. Both modes then prove the exclusion worked with a leak check against
the finished archive.

## The package database is only as good as its manifests

There is no package manager. `lfsmaint` builds a database from per-step manifests, which
means a step that installs files and captures no manifest is invisible to `owns`,
`verify` and `orphans`.

Two reporting lessons:

- **`verify` must classify expected removals.** A naive run reported 97 missing files on a
  correct system: 72 `.la` files and 19 cross-toolchain files pruned by `ch08-cleanup`,
  and 6 sshd host keys regenerated on first boot. All deliberate. Burying real problems
  under known-good noise makes the check worthless, so accounted-for removals are
  separated from unexplained ones and only UNEXPLAINED is a signal.
- **`orphans` is honest but blunt.** It reported ~38,000 unowned files, because manifests
  start at Chapter 8: everything from chapters 4-7 is unowned by construction, along with
  anything created at runtime.

## When the agent got it wrong

Worth stating, because it is the honest failure mode of this kind of work and it is why
`--check` exists.

The BLFS package list lived inside the extractor, and steps got added straight to the
generated plan instead. Nobody noticed until the multi-host split forced the list out
into `packages.py`: the extractor was **66 steps behind** the plan it supposedly
produced, carried **25 phantom entries** for an abandoned Wayland tier that were never
built, and had diverged in ordering. Running it would have deleted two thirds of the
desktop and resurrected the dead tier.

Worse, **33 recipes had been hand-tuned past what their recorded decision said** --
including one whose override was missing two of the three Mesa flags the installed build
actually used. A regeneration would have silently discarded all of it. The reconstruction
had to treat the plan and the recipe files as the source of truth, not the code that
claimed to generate them.

Both are the same failure: generated artifacts edited in place, with the edit recorded
nowhere. `--check` detects exactly that condition, and `CLAUDE.md` makes "do not edit
generated recipes in place" a rule with three sanctioned alternatives.

## Standing policies

- **BLFS Recommended dependencies get installed, not just Required** -- but checked
  against what the machine is, one level deep, not chased down every recommended dep's
  own recommended deps. `vim`'s only Recommended dependency is a GTK3 desktop GUI: right
  to skip on a headless box, and the skip is recorded rather than silent.
- **Anything on the boot path is `=y`, never `=m`.** LFS installs no initramfs, so a
  module needed to reach the root filesystem is a kernel that cannot boot, and the failure
  appears only at boot time. `kernel-config-base.sh` ends with a gate that fails the build
  instead.
- **Assert defaults whose regression is silent.** The kernel's `defconfig` leaves
  `CPU_FREQ_DEFAULT_GOV_USERSPACE=y`, which pins every core at minimum frequency forever
  because nothing writes `scaling_setspeed` -- a measured 2.1x loss on sustained CPU work
  that presents as nothing but "the machine feels slow". The gate asserts `SCHEDUTIL`.
- **Re-extraction must never lose a decision.** That is why decisions live in the override
  JSON and why `--check` exists.

## Maintenance cadence

1. Read the weekly `lfsmaint-check` journal entry. Critical/High advisories are the
   actionable signal.
2. To upgrade a package: bump the version in the host's `packages.py`, re-extract,
   `lfsbuild --only <step> --force`, then `lfsmaint db` to re-record it.
3. When a new book release lands: `lfsmaint fetch-lists`, then `lfsmaint drift` shows the
   whole delta at once.
