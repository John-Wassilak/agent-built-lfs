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

## `lfsbuild` itself can under-report a failure

Found on `laptop`, 2026-08-31, `blfs-libnotify`: the step reported `OK` with a 0-file
manifest. The log showed a real, hard failure -- `meson setup` rejecting a missing `gtk4`
dependency -- yet the driver recorded exit 0.

The cause is `set -e`'s own documented exemption, not a bug in the recipe: bash does not
abort on the failure of a command that is not the last member of an `&&`/`||` list. The
book's own universal style is `configure && build` / `build && install`, so a failure in
the first half of a chain is exactly the case `-e` lets slide -- the shell falls through
to the next line instead of stopping. Traced byte-for-byte against the real staged script
and confirmed with a minimal reproduction (`mkdir && cd && false && echo unreachable`
under `set -e` does not abort, and later, unrelated lines in the same script still run).
`libnotify`'s recipe has three blocks, each of that shape; the visible `ninja: error:
loading 'build.ninja'` came from block 2's `ninja install`, not block 0 -- blocks 0 and
1's own trailing `ninja`/`meson configure` never even ran, short-circuited away by the
same `&&` the moment the command before them failed.

`build_script()` in `bin/lfsbuild` now captures `$?` immediately after the recipe text
(before cleanup or manifest capture can overwrite it) and exits on a nonzero value instead
of continuing to the manifest-capture epilogue. This catches the failure whenever the
recipe's own final top-level statement ends up failing too -- true whenever later blocks
depend on earlier ones, which every real recipe checked so far does, since a package that
never configured has nothing for its final install step to act on. It is a mitigation for
the observed failure mode, not a proof against every one: a contrived recipe whose last
statement can succeed independent of an earlier failure would still slip through.

A repo-wide audit for other victims checked every `hosts/*/manifests/*.txt` for a 0-line
file: only `blfs-libnotify.txt` (this bug) and `blfs-glaze.txt` (a separate, unrelated
manifest-capture anomaly on a step that genuinely installed real files, confirmed against
its own log) turned up, out of 160+ completed BLFS steps. That check cannot catch a
recipe that partially installed some files before an exempted failure, since a nonzero
but wrong file count looks identical to a correct one -- there is no cheap way to rule
that out short of re-running or manually spot-checking a step.

## A tarball's own listing can still mislead `srcdir_of()`

Found the same day as the `set -e` bug above, on the very next step: `bin/lfsbuild`'s
`srcdir_of()` reads a tarball's real top-level directory from `tar -tf` rather than
guessing it from the filename -- the right call, since a name like
`firefox-140.8.0esr.source.tar.xz` extracts to `firefox-140.8.0` (no `esr`, no
`.source`). But it took the *first* listed entry's leading path component on faith.
Firefox's own tarball lists `./` as its very first entry, an explicit archive-root
marker some tar creators emit before any real path -- so `srcdir_of()` returned `.`,
and the driver's own cleanup step then ran `rm -rf "."`, which GNU `rm` refuses
outright ("refusing to remove '.' or '..' directory"), aborting the build before the
recipe ever ran. Fixed by skipping a leading `.` component exactly like the existing
skip for an empty one, then taking the first entry that is neither. No other tarball in 160+ completed steps triggered this, so this fix is scoped to the
one marker actually seen rather than an attempt to anticipate every possible
tar-creator quirk in advance.

## Stripping a live shared library in place can zero it out

The book's own chapter 8 stripping step (`ch08-stripping.html`) treats a specific list
of libraries specially -- `online_usrlib` / `online_usrbin` -- copying each to `/tmp`,
stripping the copy, then `install`ing it back atomically, rather than running `strip`
directly on the file in place. The reason is stated plainly in the book's own text:
these are libraries the running system's tools (`bash`, `find`, `strip` itself) are
actively using, and "failing to do so may render the system completely unusable."

That warning was not theoretical. A later, unrelated cleanup pass on `laptop`
(2026-08-31, freeing disk space before a Firefox retry) ran a blanket
`find /usr/lib ... -exec strip --strip-debug {}` across every "not stripped" file,
including `libbfd-2.46.0.20260210.so` -- binutils' own internal library, which `ld`,
`as`, `ar`, and `strip` itself all dynamically link against. Stripping it in place
truncated it to zero bytes, breaking the entire toolchain: no command depending on it
could run, including the tools needed to rebuild it. The chapter 5/6 temporary
toolchain (`/tools`) that could otherwise have rescued this was already gone (removed
by `ch08-cleanup` long before this point in the build).

Recovery required building a throwaway static-ish binutils *on the host* from the
project's own `binutils-2.46.0.tar.xz`, confirming empirically that a host-built,
dynamically-linked-against-host-glibc binary still executes correctly inside the
chroot (glibc's dynamic loader compatibility held), using those as temporary
`/usr/bin` replacements (original zeroed/broken files kept as `.BROKEN` alongside, not
deleted, until the real fix was verified), and then force-rerunning this project's own
`ch08-binutils` step to reinstall a correct, natively-built binutils -- which naturally
overwrote every temporary file with a properly configured one. `ar` was missed on the
first pass (only `ld`/`as`/`strip`/`objcopy`/`ranlib`/`nm`/`readelf` were rescued
initially) and had to be added once binutils' own configure failed on
"could not determine ar interface" -- worth checking the *entire* tool list a broken
shared library affects, not just the ones a first guess names.

Lesson (as first written, 2026-08-31): never run `strip` directly on a library the
running system's own toolchain depends on -- match the book's own copy-strip-atomic-
install pattern. **That lesson was not followed the next time this came up.**

It happened again, worse, on the very next `/lfs-audit` fix-up pass (2026-09-01),
despite this section already existing. A curated exclusion list was built from
`ldd $(which strip bash find xargs file)`, filtering to only the `=>`-formatted
dependency lines -- which silently drops the interpreter/loader line, since `ldd`
prints that one differently (no `=>`). The excluded-file check itself passed (no
excluded path leaked into the strip list), which is exactly why the gap wasn't
caught: the list was *self-consistently* wrong. Stripping in place then truncated
`/usr/lib/ld-linux-x86-64.so.2` -- glibc's own dynamic loader, not merely something
the toolchain depends on but the thing every dynamically-linked program on the system
depends on, `chroot`'s own shell included. Recovery this time needed a second,
larger host-side rescue build (glibc itself, not just binutils, since the loader
lives there) and, because even `sudo chroot ... bash -c` was now unusable (bash
itself needs the broken loader to execute), a fully-static host-compiled copy tool
(`gcc -static`) to place the rescued file without invoking anything inside the
chroot's own (broken) userspace at all.

A second finding, discovered only *after* both incidents, made the whole premise
moot: `file`'s "not stripped" classification checks for a `.symtab` (symbol table),
which `--strip-debug` deliberately never removes -- it only strips `.debug_*`
sections. Of the laptop's 2,942 "not stripped" files by that measure, exactly 16 had
an actual `.debug_info` section to remove; the other 2,926 would have shown
"not stripped" forever regardless of how many times they were correctly stripped.
The metric driving this entire cleanup category does not measure what it appears to
measure -- checking `readelf -S <file> | grep .debug_info` (or equivalent) is the
real test, and it also shrinks the blast radius of any mistake by two orders of
magnitude before a single file is touched.

Revised, non-negotiable rule: **stripping a live system's own files is never a direct
`strip target`, ever, no exceptions and no exclusion lists** -- exclusion lists are
exactly the mechanism that failed here twice, once by omission (a name not thought
of) and once by a tool-output-format assumption (a name silently filtered out
upstream of the list). The only acceptable form is the unconditional atomic pattern,
applied to every candidate with no carve-out:
```
mode=$(stat -c "%a" "$f")
cp "$f" /tmp/.strip_tmp && strip --strip-debug /tmp/.strip_tmp \
  && install -m "$mode" /tmp/.strip_tmp "$f" && rm -f /tmp/.strip_tmp
```
This was verified safe even against a file actively being executed by the shell
performing the stripping (`/usr/bin/xargs`, mid-loop, no crash) -- the atomic
rename is what makes "currently in use" irrelevant, which is the entire reason to
prefer it unconditionally rather than trying to enumerate what is and isn't in use.

## `lfsbuild`'s cleanup could be skipped by a *correct* abort, not just a swallowed one

A follow-on discovery while fixing the `set -e` bug above, on the very next real
failure it correctly caught: `blfs-firefox`'s `./mach build` failed (a genuine,
non-exempted top-level statement), `set -e` aborted immediately as it should -- but
`build_script()` places the driver's own cleanup (`rm -rf srcdir`) as plain sequential
lines *after* the spliced-in recipe text, in the same script. A natural, correct `-e`
abort partway through the recipe skips everything after it just as thoroughly as the
original exempted-failure bug did, including that cleanup -- so a failed Firefox
attempt left its entire 4.1G extracted-and-partially-built source tree behind, which
directly caused the very disk-space emergency being worked around when the corrupted
`libbfd` (previous section) was discovered.

Fixed by running the recipe as a genuine child process rather than splicing it inline:
the recipe is written to a temp file and invoked as `bash "recipe.sh" || RECIPE_RC=$?`.
Verified empirically that this preserves both halves correctly: a command that is not
the last member of an `&&` chain inside the child still gets the exact same silent-
continue exemption as before (it's still that child's own `set -e` handling its own
script), while *any* top-level failure in the child -- exempted or not -- never reaches
the outer script's own `-e`, because the call site is the non-last member of a `||`
list at the outer level. Cleanup and the failure gate now run unconditionally,
regardless of where or how the recipe failed. An earlier version of this fix
(capturing `$?` immediately after splicing the recipe inline) caught only the
exempted-failure case and not this one -- the difference matters, and is why this got a
second, more thorough pass rather than a quick patch.

## The package database trusted mtime, and CMake doesn't always update it

Root cause of the `blfs-glaze` 0-file manifest (`laptop`, 2026-09-01): the manifest
capture (`bin/lfsbuild`) used `find -newer /tmp/.lfsbuild-stamp`, comparing each file's
*mtime* against the time the step started. `glaze` is header-only, and its CMake
install step copied every header with the source tarball's original mtime intact
(2026-08-17) rather than refreshing it -- so every one of its 298 installed files was
"older" than the step that installed them, and the manifest recorded zero.

This is not glaze-specific, and not CMake-specific in a narrow sense -- it is any
install mechanism that preserves a source timestamp instead of stamping "now". A sweep
comparing every completed step's log (`-- Installing: <path>` lines, CMake's own
verbose install output) against its recorded manifest found **34 affected packages**,
several catastrophically undercounted: `cmake` (4 of 4011 real files recorded), `llvm`
(477 of ~3700), `hyprland` (105 of ~520), `abseil-cpp` (395 of ~790). Every one of these
had been silently invisible to `lfsmaint owns`/`verify`/`orphans` despite being
correctly installed.

Fixed two ways:

- **Going forward**: `bin/lfsbuild`'s manifest capture now uses `-cnewer` (ctime) rather
  than `-newer` (mtime). ctime is not user-settable and cannot be inherited from a
  source tree -- the kernel sets it to the real time of the last inode change on *this*
  filesystem regardless of what mtime an install tool chose to write, so it has no
  equivalent failure mode.
- **Backfill for already-built steps**: reconstructed each affected manifest from its
  own install log's `-- Installing:` lines, keeping only paths that are currently real
  files on disk (filtering out directories and already-cleaned-up build-tree paths the
  same way the driver's own `! -type d` convention does). One package (`libzip`)
  initially looked *worse* after reconstruction (149 → 18) until traced to a second,
  unrelated cause: its man pages were compressed to `.gz` by an earlier, separate
  cleanup pass in this same session, *after* its install log was written, so the log's
  literal (uncompressed) paths no longer existed -- fixed by also checking for a `.gz`
  sibling when the bare path is missing. Worth remembering generally: a reconstruction
  that produces fewer files than the original is a signal to investigate before trusting
  it, not a result to accept because the mechanism otherwise looks sound.

`find -cnewer` has its own known limits worth stating rather than assuming away: a
step that only `chmod`s or `chown`s a file it did not itself create would also bump
ctime and could cause a manifest to over-claim a file another package owns (unlike
`server`'s already-documented multi-owner conflicts from genuine double-installs, this
would be a false attribution from the *capture heuristic*, not the packages
themselves) -- not observed in this sweep, but worth keeping in mind if `lfsmaint db`
ever reports an unexpected multi-owner conflict on a from-scratch build.

## A build's own scratch cache can look identical to installed output

Related to the ctime fix above, but the opposite failure direction: `-cnewer` fixed
files that were wrongly *excluded* because their mtime was too old; a fresh build cache
can get wrongly *included* because there is nothing distinguishing "written by this
step's real install" from "written by this step's own tooling as scratch space" once
both are simply newer than the stamp. Found building `tailscale` (laptop, 2026-09-01):
its tarball ships no `vendor/` directory, so `go build` downloaded ~1.7G of module
cache into `$HOME/go` and `$HOME/.cache/go-build` -- both freshly written during the
step, both swept into the manifest as 16,629 "installed" files for a package that
actually installs 4. Same root issue as `blfs-go.sh`'s own documented `/root/build-go`
cleanup, just not yet applied to its sibling recipe. No generic fix at the driver
level -- a build tool's own cache directory is not something `bin/lfsbuild` can know
about in advance -- so the responsibility sits with the recipe: any hand-authored
recipe using a language toolchain with its own cache/download directory (Go's
`GOPATH`/`GOCACHE`, similarly Cargo's `CARGO_HOME`, pip's cache, etc.) should remove
that cache before the recipe exits, the same way `/root/build-go`-style scratch
directories are already cleaned up throughout this project.

## `--force` reruns can hit state a fresh source tree doesn't reset

`bin/lfsbuild --force` re-executes a step's recipe from a freshly re-extracted source
tree, which resets everything *the build* touches -- but a step that also mutates
persistent system state (a user account, an appended-to config file) can leave that
state from a previous attempt still in place, and the book's own commands are rarely
written to tolerate that. Hit three times in one sitting (laptop, 2026-09-01), all the
same underlying class:

- `blfs-polkit` block 0's `useradd` failed outright on a retry after an earlier attempt
  had already created the `polkitd` user before failing later in the same step.
- `blfs-adduser-john`'s own `useradd` hit the identical failure applying an unrelated
  password change to an account that already existed.
- `blfs-openssh`'s `echo "PermitRootLogin no" >> sshd_config` didn't fail at all, which
  was worse: the file already had `PermitRootLogin yes` appended from an earlier
  build, and the new line landed *after* it. sshd honors the first occurrence of a
  repeated directive, so the stale value silently kept winning even though the recipe
  looked correct and the build reported success.

The `useradd` cases are caught by a build failure and are easy to notice. The `>>`
case is not -- it succeeds, reports success, and the wrong config takes effect anyway.
Any override that appends to a file expected to persist across steps needs to strip a
prior occurrence first (`sed -i '/^Directive /d' file` before the `echo ... >>`), not
just add the new line; any override with a `useradd`/`groupadd`-style command needs a
check-first guard (`id user >/dev/null 2>&1 || useradd ...`) the same way. Worth
specifically re-checking the actual built state (not just build log success) after any
`--force` rerun of a step that touches config files or system accounts, since this
class of bug does not announce itself.

## Two `bin/` tools assumed a dedicated `/mnt/lfs` partition

`bin/lfs-umount` and `bin/lfs-archive` both hardcoded `CHROOT_TREE=/mnt/lfs`, unlike
every other tool in `bin/`, which resolves the tree from the host's own `chroot_tree`
(`host.toml`, via `lfshost.resolve()`) the same way it resolves everything else.
`server`'s tree really does live at `/mnt/lfs`, its own partition, so this went
unnoticed through that entire build. `laptop`'s doesn't -- `chroot_tree` points inside
this repo checkout (`hosts/laptop/CLAUDE.md`'s disk-space decision) -- so both tools
silently treated the tree as absent: `lfs-umount` reported "clean: nothing mounted
under /mnt/lfs" while the real tree (elsewhere) still had six virtual filesystems
bound into it, and `lfs-archive` refused with "no tree at /mnt/lfs; use --live" even
though a fully populated tree existed one `--host laptop` away.

Fixed by giving both the same `--host`/`$LFS_HOST`/hostname resolution as `lfsbuild`
and every other tool (a small inline `python3 -c 'import lfshost; ...'` call, since
both are bash scripts and `lfshost.py` is a Python module built for `import`, not a
CLI with a single-value output mode). A second, related bug in `lfs-archive`'s
free-space guard surfaced at the same time: it used `df --output=used "$SRC"`, which
reports usage for the whole filesystem `$SRC` lives on, not `$SRC` itself -- exactly
right when the tree has a dedicated partition, wildly wrong (151GB reported, ~5GB
actual) when the tree is a subdirectory of a shared volume. Fixed by measuring with
`du -sx`, respecting the same exclusions tar will apply, reusing that one measurement
for both the space guard and the dry-run's content estimate rather than computing it
twice. Any `bin/` tool that names a fixed path instead of resolving it is worth
grepping for before trusting it against a second host with a non-default layout.

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
