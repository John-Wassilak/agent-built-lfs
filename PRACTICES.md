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

### It happened a third time, and the reason is the one that matters (2026-09-21)

On `server`, from `/lfs-audit`'s own section-G snippet -- which still read
`strip --strip-debug "$1"`, in place, on a live root. Everything above was already
written, on this page, in this repo, when that pass ran. **A rule recorded only in prose
is not a rule.** The two earlier incidents produced a correct pattern and a
"non-negotiable" heading; neither produced an edit to the file that actually issues the
commands, so the third machine ran the original mistake verbatim. When a practice here
names a specific command, the skill, recipe or `bin/` tool carrying that command has to
be changed in the same session, or the practice is a comment.

Two things this incident established that the first two did not:

- **`strip` never renames.** The safety of the copy-strip-`install` pattern was credited
  above to "the atomic rename". `strip` does not do one. Measured on binutils
  2.47.20260726: `strip --strip-debug <file>` leaves the *inode number unchanged*,
  whatever the link count -- it writes a temp file beside the target, then truncates the
  target and copies back into it. That is why an interrupted run yields a zero-length
  library rather than an untouched one, and why a mapped file is read back rewritten. The
  property that makes `install` safe is `install`'s, not strip's: it unlinks the
  destination and creates a new inode, so a process holding the old one keeps reading the
  old one. Verified directly -- a process whose `/proc/<pid>/exe` was the file being
  replaced stayed alive, its `exe` became `... (deleted)`, and it exited 0.
- **`install` breaks hard links, and this tree is full of them.** `git` ships 150 names on
  one inode; `gcc`/`g++`/`c++`, the `x86_64-pc-linux-gnu-*` aliases, `perl`, and the
  e2fsprogs `fsck.ext[234]`/`mkfs.ext[234]` families several more. A naive
  copy-strip-`install` sweep over paths explodes every one of those sets into independent
  copies -- on `git` alone that is 149 extra files, which on a pass whose entire purpose
  is reclaiming disk space is worse than doing nothing. The corrected form in
  `.claude/skills/lfs-audit/SKILL.md` iterates over *inodes*, not paths: one
  `find -printf '%i\t%p\n'` pass up front, strip each inode once, then `ln -f` the
  remaining names back onto the new inode.

The `file`-versus-`readelf` finding above also needs a caveat: the ratio is
host-dependent and `laptop`'s 16-of-2,942 is not the general case. On `server`'s 13.1
tree, `file` called 988 of 1,263 files in `/usr/bin` and `/usr/sbin` "not stripped" while
414 genuinely had `.debug_info`. Over-reporting by 2.4x rather than 180x -- still the
wrong metric, still worth correcting, but the savings on a fresh BLFS tree are real and
the finding is not a reason to skip the category.

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

## An `auto` meson feature turns a build-order mistake into a silent missing feature

`seq` decides build order, and for a package whose optional dependencies are meson
`feature` options that default to `auto`, `seq` also decides *what gets built at all*.
Get the order wrong and meson does not complain: it probes for a library that has not
been built yet, disables that half of the package, and installs cleanly with exit 0.

Found on `laptop` (2026-09-04), and the shape is worth remembering because none of the
usual signals fire. `pipewire` sat at seq 123 and `alsa-lib` at seq 130, so pipewire
built with no ALSA SPA plugin -- `/usr/lib/spa-0.2/` had no `alsa/` directory, and the
step's own manifest confirmed it had never installed one. Everything downstream then
behaved *plausibly* for days: `pipewire` and `wireplumber` both started and stayed
running, `systemctl --user` showed every unit active, `pw-cli info 0` answered normally,
and `wpctl status` printed a healthy graph -- with zero Devices, Sinks and Sources
against four working cards in `/proc/asound/cards`. No failing unit, no error in any
build log, nothing for `--check` to catch. The only text on the machine that named the
real cause was one line in wireplumber's journal ("PipeWire's ALSA SPA plugin is missing
or broken"), two packages away from the mistake.

This is the same failure shape as the `blfs-gdk-pixbuf` loader trap already recorded in
`recipes/blfs-<ver>/overrides.json`, where the book's own defaults left every image loader
disabled and the symptom was an unrelated launcher aborting on an icon. Both were
absence, not breakage, surfacing far from the cause.

Three things follow, all cheap:

- **Pin the features you are relying on**, rather than leaving them `auto`. `-D
  alsa=enabled` fails at configure time if alsa-lib is missing; `auto` ships a mute
  system. `auto` is only appropriate for a dependency the recipe genuinely does not care
  about -- and if a recipe's header comment lists which optional deps it *meant* to skip
  (pipewire's did), anything not on that list should be pinned on.
- **When placing a package in `seq`, check its optional deps, not just its required
  ones.** Required deps fail loudly and get caught immediately. Optional ones are the
  ordering bugs that survive to a live system.
- **After building anything that enumerates hardware, verify against the hardware.** Not
  "the daemon is running" -- `wpctl status`, `/dev/video*`, `bluetoothctl list`, an actual
  device count compared against `/proc` or `/sys`. A running daemon with an empty device
  list is the expected presentation of this whole class of defect.

Correcting one of these after the fact does not mean renumbering: `seq` numbers are
permanent, so pipewire/wireplumber moved to the unused fractional seqs 130.5/130.6 (just
after alsa-lib, keeping their position relative to everything downstream) and 123/124
were left as documented gaps.

And the mirror-image trap, found on `laptop` 2026-09-07 building
`xdg-desktop-portal-gtk`: an `auto` feature can *hard-error* instead of degrading, so
"it is auto, it will sort itself out" is not safe in either direction. That package
declares `option('wallpaper', type: 'feature', value: 'auto')`, and the build died at
configure time with `ERROR: Dependency "gnome-desktop-3.0" not found, tried pkgconfig
and cmake`. The reason is in one line of `src/meson.build`: the guard is
`get_option('wallpaper').allowed()`, and `allowed()` is true for `auto` -- it means only
"not disabled" -- after which the code calls plain `dependency('gnome-desktop-3.0')`,
whose `required` defaults to true. An `auto` option guarding a required `dependency()`
call is auto in name only. Read the guard, not the option's default: `.allowed()` needs
an explicit `-D <feature>=disabled` to skip, while `.enabled()` or a
`dependency(..., required: get_option(...).enabled())` genuinely self-disables. BLFS's
own Command Explanations had the fix (`-D wallpaper=disabled`) and it is now a recorded
review decision.

## `/run/user/$UID` has two owners on a PAM-less box, and the loser's sockets vanish

Both machines here run systemd built `-PAM` (`systemctl --version` confirms it), which
means no `pam_systemd`, so `systemd-logind` never opens a session for a console login.
`loginctl list-sessions` prints "No sessions" while a user is visibly logged in on a tty
and running a desktop. Two consequences worth knowing before touching either one:

**`user@$UID.service` cannot start on its own.** It relies on `PAMName=systemd-user` for
more than authentication -- `pam_systemd` is what exports `XDG_RUNTIME_DIR` into the user
manager -- so with `-PAM` it exits 1 with "Trying to run as user instance, but
$XDG_RUNTIME_DIR is not set". Anything that needs a user systemd instance is dead with no
failing unit to point at, notably the pipewire/wireplumber units BLFS tells you to enable
`--global`. The fix is two pieces: a drop-in setting
`Environment=XDG_RUNTIME_DIR=/run/user/%i`, and `loginctl enable-linger <user>` so
something actually starts the manager at boot.

**But `enable-linger` must not be run while a desktop is already up.** It pulls in
`user-runtime-dir@$UID.service`, which mounts a fresh tmpfs at `/run/user/$UID`. If a
compositor started first -- using the plain directory a `tmpfiles.d` rule created, which
is how both hosts bootstrap `XDG_RUNTIME_DIR` without PAM -- systemd mounts straight over
its `wayland-N` socket, `hypr/`, and `ssh-agent`. Nothing crashes and nothing logs:
existing processes hold open fds and keep working, so the compositor looks perfectly
healthy while *new* clients silently cannot connect. It presents as "the launcher and
terminal hotkeys stopped working". `findmnt /run/user/$UID` is the one-command check.

**The intuitive cleanup destroys the session.** `systemctl stop
user-runtime-dir@$UID.service` runs `systemd-user-runtime-dir stop $UID`, which unmounts
*and removes the directory and everything revealed underneath it* -- verified on a
throwaway UID rather than guessed. Recover by stopping only `user@$UID.service` (safe:
`BindsTo=` is one-directional, and the runtime-dir unit has `StopWhenUnneeded=no` and no
`RequiredBy`/`WantedBy`, so nothing garbage-collects it) and then `umount
/run/user/$UID` **by hand**, so no `ExecStop` ever runs. Note that `loginctl
disable-linger` is also not a safe way to back the change out mid-session, for the same
reason.

Order it correctly instead and none of this comes up: enable linger, then reboot, so the
tmpfs is mounted during boot and the compositor starts into it. `laptop`'s
`start-hyprland.sh` now waits for `$XDG_RUNTIME_DIR` to be a mountpoint when linger is
enabled, which closes the race rather than relying on winning it.

## The kernel recipe reads a *staged copy* of the config script, not the repo's

`ch10-kernel` runs `bash /sources/kernel-config.sh`, and nothing in `bin/` puts that file
there. `hosts/<h>/kernel-config.sh` and `bin/kernel-config-base.sh` are copied into
`/sources` by hand, which the header of each file says -- and then the copies sit there,
looking current, for as long as the machine lives.

Cost of forgetting, measured on `laptop` 2026-09-04: a 22-minute rebuild that recompiled
the whole tree against a config script three days stale and produced a `/boot/config-6.18.10`
byte-identical to the one it replaced. It reports `OK` and it reports the right build time.
Nothing fails. The only symptom is that the options you added are still absent afterwards,
which looks exactly like Kconfig having dropped them for an unmet dependency -- the wrong
place to start debugging, and the place the next hour goes.

Two habits close it:

- Re-stage both files as part of editing either one, not as a step before the build:
  `install -m755 hosts/<h>/kernel-config.sh bin/kernel-config-base.sh /sources/`.
- Verify the *build tree's* `.config` a minute into the run rather than `/boot/config-*`
  after it. `grep -E '^(# )?CONFIG_(NEW|SYMBOLS)\b' /sources/linux-*/.config` answers in
  one second whether the next twenty minutes are worth waiting for. `/boot/config-*` only
  tells you after `make modules_install` has already overwritten `/lib/modules`.

The real fix is for `lfsbuild` to stage the pair itself and refuse to run `ch10-kernel` on
a `/sources` copy that differs from the repo -- the same `--check` discipline the recipe
extractors already have. Not done yet.

## `--no-build-isolation` can silently stamp a Python package version 0.0.0

Found on `laptop`, 2026-09-07, in `blfs-python-dateutil` and `blfs-aiohttp-oauthlib`.

`pip3 wheel --no-build-isolation` is the right call when the build backend is already
installed -- it avoids a pointless network fetch, and most of the pure-Python steps here
use it. The trap is that a `[build-system] requires` list, or a legacy
`setup_requires=[...]`, holds more than the backend. When it also names
`setuptools_scm`, and `setuptools_scm` is not installed, the wheel **still builds and
still works**. It just records its version as `0.0.0`, because for these packages
`setuptools_scm` is the only source of a version -- there is no static `version =`
anywhere in `setup.py` or `setup.cfg` to fall back to.

Nothing notices until something pins a floor. `recurring-ical-events` requires
`python-dateutil>=2.8.1`, and `pip install` rejected an install that was present,
importable and functionally correct:

    ERROR: Could not find a version that satisfies the requirement
    python-dateutil<3.0.0,>=2.8.1 (from versions: none)

Two lessons, both general:

- **`lfsmaint` cannot catch this.** Its version column comes from the tarball name in the
  plan, so the database read `python-dateutil 2.9.0.post0` for two days while the install
  said `0.0.0`. This is the same class as the manifest lesson above: the database reports
  what the plan claims, not what landed on disk. Only
  `ls /usr/lib/python3.*/site-packages/*.dist-info` shows the truth, and that scan is
  cheap enough to be worth running after any batch of Python steps -- one pass found the
  second case, which had never broken a build and would not have been noticed otherwise.
- **A repair needs `--upgrade`, not `--force`.** `lfsbuild --only <step> --force` reruns
  the recipe, but `pip install <name>` inside it considers a bare requirement already
  satisfied by the broken `0.0.0` and does nothing, so the step passes and changes
  nothing. The recipe itself has to carry `--upgrade` to be able to fix its own earlier
  output. With `--no-index --find-links dist` the only candidate pip can choose is the
  wheel just built, so `--upgrade` costs nothing on a fresh system.

Standing fix in both recipes: leave build isolation on, and echo
`pip3 show <pkg> | grep '^Version:'` at the end so the log carries the answer instead of
requiring an archaeology session.

## `pip install --user` leftovers outshadow every managed copy

Same session, and it is why the tool in question had been half-working.
`/home/john/.local/lib/python3.14/site-packages` held three packages from an earlier
`pip install --user`. User site precedes system site on `sys.path`, so those copies won
every import: invisible to `lfsmaint owns`, unmanaged by anything, and they would have
kept shadowing three brand-new system packages, making the whole build a no-op from the
consuming program's point of view.

`--no-user` on the install line (already the pattern here) stops a *recipe* from writing
there. It does nothing about what a human already put there. On a box with no package
manager, `ls ~/.local/lib/python3.*/site-packages` belongs in any audit that touches
Python, and the check is `importlib.util.find_spec(mod).origin` -- an import that
succeeds proves nothing about which copy answered it.

Not everything found there is removable: two of the five entries existed nowhere else on
the system, so deleting them would have broken whatever uses them. Those are the real
signal -- an unmanaged install that nothing in the build provides is a missing step, not
a leftover.

## A recipe that starts a daemon sweeps that daemon's state into its own manifest

Third variant of the manifest-boundary problem, after the ctime fix and the scratch-cache
one above, and the only one where the *correct* recipe is what causes it. `blfs-tor`
(laptop, 2026-09-07) ends with `systemctl enable tor` and `systemctl restart tor`, which
is right -- on a booted native host that is what "install and enable" means, and a future
machine running this step should end up with a running service, not a stopped one. But the
daemon then writes its consensus cache, state file, lock and entry-guard record into
`/var/lib/tor` while the step is still running, and every one of those files is newer than
the step's own stamp, so the manifest claimed tor "installed" runtime state it merely
created on first start.

The scratch-cache case had no generic fix because a build tool's cache location is not
knowable in advance. This one is different: a service's state directory is a fixed,
declared property of the package (it is in the unit's `StateDirectory=` and the daemon's
own config), so it belongs in the driver's `MANIFEST_NOISE` alongside systemd's
`timesync/clock` and `random-seed` -- which are the same category of file, put there for
the same reason. The rule for a new step that enables a daemon: if the service writes
under one of `MANIFEST_ROOTS` at runtime, add that path to `MANIFEST_NOISE` in the same
change, or the package's file list is wrong the first time it is captured and stays wrong.
Directories themselves are already excluded (`! -type d`), so only the contents need
naming.

**The daemon does not have to be one the build started.** Fourth variant, found
2026-09-15 on `laptop` while installing an unrelated package: `blfs-zbar`'s 28-file
manifest claimed two `/var/lib/tailscale/tailscaled.log*.txt`. Nothing about zbar touches
tailscale. `tailscaled` has simply been running since the host joined the tailnet, and it
rotated a log inside that step's stamp window. The sweep is a `find -cnewer` over `/var`
with no idea which process wrote what, so on a native host *every already-running
service* is a standing source of manifest noise, not just the one the current recipe
enables. That makes it worth auditing rather than only reacting to:

    grep -h '^/var/lib/' hosts/<h>/manifests/*.txt | sort | uniq -c

On `laptop` that one line found four contaminants at once -- tailscale's logs and node
state across five manifests, a NetworkManager DHCP lease claimed by five more, a bluez
link key from a headset that paired during `blfs-nghttp2`, and 25 leftover upower history
files in manifests captured before the upower exclusion existed and never backfilled. All
four are now in `MANIFEST_NOISE` and the manifests are scrubbed.

The same audit is what shows where the line is. Three `/var/lib` paths survived it and
should: `systemd/catalog/database`, `nss_db/Makefile` and `dbus/machine-id`. Each is
created by the very step that claims it, which is the test -- **a file under a service's
state directory belongs to the package only if the installing step is what wrote it**,
not merely if the daemon happened to be running.

## The manifest noise filter cuts both ways

`bin/lfsbuild`'s manifest sweep is `find -cnewer` over `MANIFEST_ROOTS`, minus a
`MANIFEST_NOISE` regex for churn that every step touches. Two failures live at opposite
ends of that filter, and both were found in the same pass (2026-09-21, `server`).

**Too loose.** Language toolchains cache under `/root` in places that are neither
dotfiles nor named `build`: go's module cache at `/root/go/pkg/mod`, and
`blfs-nvidia-470xx`'s full kernel build at `/root/kbuild`. Three manifests recorded
275,000 phantom files -- `blfs-openbao` claimed 106,094 installed files when it installs
four. `lfsmaint owns` answered with the Go module cache. `/sources` was left out of
`MANIFEST_ROOTS` from the start for exactly this reason; the same swamping walked in
through `/root` instead. Rule of thumb: any step that fetches dependencies at build time
needs its cache location checked against the filter before its manifest is trusted.

**Too tight, and worse because it is silent.** The filter excludes `^/var/log/` and
`^/root/\.` as churn, which is right for almost every step and wrong for the two whose
deliverable *is* that path: `blfs-fix-varlog` installs `/var/log/{btmp,faillog,lastlog,
wtmp}` and `blfs-skel-vimrc-and-root` installs `/root/.bashrc` and friends. This is not
hypothetical -- the same step, same recipe, captured twice:

    hosts/server/manifests/blfs-fix-varlog.txt          4 files   (before the rule)
    hosts/server-rebuild/manifests/blfs-fix-varlog.txt  0 files   (after)

The second run reported success and recorded nothing. Nothing flagged it.

**A third gap, same shape: `MANIFEST_ROOTS` has no `/home`.** Any step installing into a
user's home records an empty manifest -- `blfs-claude-code` (npm global prefix under
`/home/john`) and `blfs-authorized-keys-john` both do, on every host that built them.
`lfsmaint` therefore does not know those files exist at all.

The general shape: a global "this is not package content" rule is a statement about most
steps, not all of them, and a manifest that comes back empty is indistinguishable from a
step that installed nothing. Neither `--check` nor the build catches it. The structural
fix is per-step scoping -- each step declaring the roots it owns and the noise it is
exempt from -- rather than more global regex tuning, since narrowing the global rules
readmits churn everywhere else and adding `/home` wholesale sweeps in every dotfile any
step happens to touch. Not implemented. Until then: an empty manifest is a bug in the
filter until proven otherwise, and `ch08-cleanup` is the only step legitimately empty.

Corollary for repair: do not fix historical manifests by re-running the current
`MANIFEST_NOISE` over them. That deletes those two steps' real content along with the
junk. Filter for the specific pollution instead.
## The book's Google Location Service key is dead, and BLFS spends it twice

Firefox's BLFS page has you write the book's shared Google Location Service key into a
`google-key` file and pass `--with-google-location-service-api-keyfile`; the GeoClue page
writes the same key into `/etc/geoclue/conf.d/90-lfs-google.conf` as the `[wifi]` source
URL. Both landed correctly on `laptop` (the key is verifiable after the fact in
`omni.ja`'s `modules/AppConstants.sys.mjs`), and geolocation still failed on every
request, because Google answers that key with

    403 PERMISSION_DENIED: You must enable Billing on the Google Cloud Project

Verified 2026-09-08, and verified again the same day against the current development
book, r13.1-84, which still ships the identical key on both pages. So on any machine
built from BLFS 13.0, both the browser-level and the OS-level geolocation providers are
wired to a service that refuses them, and the symptom is a `GeolocationPositionError`
code 2 that looks exactly like a missing dependency.

**Building GeoClue is the fix -- but only if you drop the book's config block.**
GeoClue-2.8.0's own compile-time default for that same `[wifi]` url is already
`https://api.beacondb.net/v1/geolocate` (`meson_options.txt`, `default-wifi-url`),
keyless and public-domain. beaconDB is the Ichnaea-compatible successor to the Mozilla
Location Service that Mozilla shut down in June 2024, and pointing GeoClue at it is what
Gentoo, Fedora, NixOS, Guix and Void all do. The book's `90-lfs-google.conf` *overrides*
that working default with a dead endpoint, so writing the file is strictly worse than
skipping it. `recipes/blfs-<ver>/overrides.json` drops the block for every host on that
release.

Three things that cost time on the way there, none of them host-specific:

- **beaconDB coverage is regional, and "no coverage" looks like an answer.** It never
  errors; it falls back to IP and says so. Handed 12 APs scanned off `laptop`'s own
  radio it matched none and returned `{"accuracy":25000,"fallback":"ipf"}` 16.6 km away.
  Fedora's own writeup says to check the beaconDB map before switching. Test it with a
  real scan before assuming a built GeoClue will be accurate -- one `curl` against
  `api.beacondb.net/v1/geolocate` with a scanned AP list answers it in seconds.
- **GeoClue does not rank its sources and hand out the best one.** It hands out whichever
  answers first and updates later. With `[wifi]`/`[ip]` enabled alongside a
  `/etc/geolocation` static position, `where-am-i` showed the 25 km GeoIP fix first and
  the 30 m static fix about two minutes later -- and a `getCurrentPosition()` caller
  takes the first and stops. `geoclue(5)` says to disable the other sources when using
  the static one; it means it. This is invisible unless you watch more than the first
  fix.
- **The book names Google; GeoClue's own config names three providers.** Stock
  `/etc/geoclue/geoclue.conf` documents beaconDB (the compiled-in default), Positon, and
  Google, with commented URLs for each. Positon ships an upstream key in that file, usable
  where the service is non-commercial (their wording, quoted in the config, names Fedora,
  Debian and Ubuntu as fine and RHEL/SLE as not). On `laptop` beaconDB had no wifi data and
  Positon knew every AP in range, returning a 21 m trilaterated fix where beaconDB fell
  back to IP at 25 km. Coverage is per-provider *and* per-location, so try more than one
  before concluding that keyless geolocation is a dead end -- and read GeoClue's own config
  file rather than the book's page for what the options are.
- **Probe a geolocation service with the payload the real client sends, or you will get a
  false negative.** A `curl` of Positon carrying only `macAddress` and `signalStrength`
  returned `{"raw":[],"fallback":"ipf"}`, indistinguishable from a total miss. GeoClue also
  sends `ssid`, and with SSIDs the same six APs all resolved. That one omitted field was
  the difference between "no coverage, go buy a GPS" and a working 21 m fix. The cheap
  check is to let the daemon make the request and read its log -- geoclue with
  `G_MESSAGES_DEBUG=all` prints the full URL and the response body. (Provider-specific, not
  protocol-wide: beaconDB returned the identical IP fallback with and without SSIDs.)
- **Turn `[ip]` off once `[wifi]` actually works.** They run concurrently and GeoClue emits
  whichever returns first. IP answers in ~200 ms, a wifi query takes ~4.5 s, so
  `getCurrentPosition()` takes the coarse guess and stops -- Firefox's first callback was
  `acc=5000` while the 21 m fix arrived only on the third `watchPosition` update. Disabling
  `[ip]` makes the real fix the first answer, at the cost of returning nothing at all when
  no APs are in range.
- **An app being `allowed=true` in `geoclue.conf` does not bypass the agent.** GeoClue's
  `Start()` parks any request for 5 s waiting for an authorization agent to register; on
  expiry it completes the request only if the `[agent]` whitelist is *empty*, and
  otherwise fails with `ACCESS_DENIED "'<app>' disallowed, no agent for UID <n>"`
  (`src/gclue-service-client.c`). Stock `geoclue.conf` whitelists five agents, so the deny
  branch is the default one. GNOME Shell, Phosh and elementary embed an agent; a bare
  wlroots compositor does not, and geoclue's own
  `/etc/xdg/autostart/geoclue-demo-agent.desktop` only helps if something processes XDG
  autostart. On such a session, start `geoclue-2.0/demos/agent` yourself -- a systemd
  `--user` unit does it without depending on the compositor's config. The symptom
  otherwise is a bare `getCurrentPosition` timeout with nothing in the journal, which
  looks like a missing provider rather than a refused authorization.
- **GeoClue's `vapi` option is a hard boolean, not a feature.** It defaults to `true` and
  `libgeoclue/meson.build:94` passes it straight into
  `find_program('vapigen', required: get_option('vapi'))`, so a missing Vala fails the
  configure step outright rather than skipping the binding -- unlike libsoup3, which
  builds without Vala and says nothing. `-D vapi=false` if Vala is not in the build.
  Same shape as the `auto`-feature trap two sections up: read the option's type and its
  use site, not the book's dependency list.

Two Firefox facts from the same investigation, still true and still worth knowing even
though `laptop` no longer needs either:

- `geo.provider.network.url` is a pref, not a compile-time constant, and it will fetch
  any URL including a `data:` URL holding a literal answer, which Firefox parses with the
  same JSON reader it uses for a real provider. That makes a hardcoded position a
  one-line change instead of a ~4 h Firefox rebuild -- useful as a stopgap, though a
  GeoClue static source is the better answer because every application sees it. To set a
  pref for every profile and every user without owning a profile directory, use
  autoconfig: `<installdir>/defaults/pref/autoconfig.js` naming `general.config.filename`,
  plus `general.config.obscure_value = 0` or the cfg is read as ROT-13 and silently
  ignored -- and the first line of the cfg is *always* skipped, so it must be a comment.
- The book's mozconfig keeps `--disable-necko-wifi`, so Firefox does no wifi scanning of
  its own (confirm with `grep -a nsWifiMonitor libxul.so` -- no hits). Firefox alone
  therefore yields IP-level accuracy even from a working provider; wifi accuracy needs
  GeoClue to do the scanning.

Last, a debugging fact that cost an hour: a page can call `getCurrentPosition`
successfully while `navigator.permissions.query({name: 'geolocation'})` still answers
`prompt`, because an Allow from the doorhanger is not necessarily persisted -- `laptop`'s
profile had 5 rows in `permissions.sqlite` and none of type `geo`. A site that wants a
durable grant rejects that state, with a message that reads like the position itself
failed. Check the permission database, not just the API call.

The general rule: **a book recipe that embeds a third-party service credential is a
liability with a shelf life**, and the upstream package often already knows better --
check its own defaults before adopting the book's configuration block. That the feature
compiled in is not evidence the feature works: query the service directly (one `curl`,
above) before believing it, and before building anything downstream of it.

## Re-running a completed step over its own install *under*-reports its manifest

Fourth variant of the manifest-boundary problem, and the mirror image of the three above:
they all recorded too much, this one records too little. Found on `blfs-nginx` (laptop,
2026-09-08) while iterating on a hand-authored recipe against a live host.

The sweep is `find -cnewer` against a stamp touched at the start of the step, so it sees
files whose inode changed *during this run*. A well-behaved installer is idempotent -- nginx
generates its install rules as `test -f <conf> || cp conf/<conf> <conf>` for `nginx.conf`,
`mime.types`, `fastcgi.conf` and the fastcgi/scgi/uwsgi params files, and this recipe's own
account creation and config writing are `getent ... ||` and `[ ! -f ... ]` guarded for the
same reason. On a re-run every one of those guards correctly does nothing, so the files are
not newer than the stamp and silently drop out of the file list. The manifest went 28 files
to 13, losing `/etc/nginx/mime.types`, all four params files and the whole passwd/group
family, and *gaining* `/usr/sbin/nginx.old` -- the rename `make install` performs on a
running binary, which is not an installed file at all.

Nothing fails and nothing warns. The step reports OK, the service works, and the package
database quietly holds a file list that would under-report the package forever after.

The fix is not to hand-edit the manifest into what it should have been: remove what the
step installs -- including the system account, or the passwd family stays missing -- and
re-run clean, then check the file list actually reproduces. On `blfs-nginx` it came back at
28 files identically. The general rule: a manifest captured by a `--force` rerun over an
existing install is not trustworthy, and any recipe iteration that ends in `--force` should
end in a clean re-capture instead. This compounds with the `--force` section above, which
covers the same reruns *failing*; here they succeed and the damage is invisible.

## The daemon-state manifest rule extends to daemons the step has nothing to do with

Addendum to the `blfs-tor` section above, found the same way (`blfs-nginx`, laptop,
2026-09-08). That section's rule is about the step's *own* service writing state while the
step runs. The same sweep also catches any *unrelated* daemon that happens to write under
`MANIFEST_ROOTS` during the build window: nginx's manifest claimed five
`/var/lib/upower/history-{charge,rate,time-empty,time-full,voltage}-JLab_JBuds_Sport_ANC_4-*.dat`
files, because a bluetooth headset connected while the step was compiling and upower wrote
its battery history.

`^/var/lib/upower/` is now in `MANIFEST_NOISE` for that reason -- upower writes those files
on a timer for the battery and for every bluetooth peripheral reporting a battery level, so
this is not specific to one headset or one host. The broader point for reviewing a new
manifest: a file list is not only checked for what is *missing*, it is checked for entries
that have no business belonging to this package. A path under `/var/lib/<some other
service>/` in a package's manifest is a bug in the exclusion list, not a discovery about
the package.

Same case, 2026-09-24 on `server`: Docker and containerd data roots. A build that
runs while compose containers are up picks up their named-volume writes (a Grafana
database, a Postgres WAL segment in `blfs-nginx`'s case). On any host that runs
containers, expect every step to hit this; `^/var/lib/docker/` and
`^/var/lib/containerd/` are in `MANIFEST_NOISE`.

## A sysctl written to `conf/default` can be a no-op, and for `accept_redirects` it is

The BLFS Personal Firewall script (`postlfs/iptables.html`), which this project's
`blfs-iptables` step installs as `/etc/systemd/scripts/iptables`, hardens the network
stack with a block of `echo <n> > /proc/sys/...` lines. Three of them write
`net.ipv4.conf.default.*`. One of those three does nothing at all, and it is the one
whose comment says "Disable ICMP Redirect Acceptance".

Two independent reasons, both worth knowing beyond this one knob:

- `conf/default/*` is not a fallback for interfaces that lack a value. It is the
  template copied into an interface's config *when the interface is created*. A
  boot-time script writing `default` changes nothing about `eth0`, which already exists.
- Whether `conf/all/*` is a floor, a ceiling, an override or irrelevant is per-knob, and
  the kernel header is the only honest source. `include/linux/inetdevice.h`:

      IN_DEV_RPFILTER   -> MAXCONF   max(all, interface)          -- rp_filter
      IN_DEV_ARP_IGNORE -> MAXCONF   max(all, interface)
      IN_DEV_RX_REDIRECTS -> ANDCONF when forwarding is on,
                             ORCONF  when it is off               -- accept_redirects

  `max()` means a safe value in `all` cannot be undone by an interface, which is why the
  book's `rp_filter` line is harmless. `OR` means the opposite: an unsafe value in `all`
  cannot be fixed by an interface. `conf/all/accept_redirects` defaults to 1, the book's
  script never writes it, and a Personal Firewall host is not forwarding -- so after
  running the book's own hardening script, every interface reads
  `accept_redirects = 0` and every interface accepts ICMP redirects.

Fixed in the shared layer (`recipes/blfs-<ver>/overrides.json`, `blfs-iptables` block 2),
which
now writes `conf/all/accept_redirects` alongside the book's `default` line. Keeping both
is deliberate: `all` closes it now, `default` does the job the book intended for
interfaces brought up later (`wg0`, `tailscale0`).

The general practice, which is not specific to firewalls:

- **A hardening line is not done until the effective value has been read back.** Not the
  value you wrote -- the value the kernel consults. For anything under
  `net.ipv4.conf.*`, that means reading `all`, `default`, and each real interface, then
  checking the header for how they combine. `sysctl -a | grep <knob>` shows the
  disagreement in one screen.
- **`conf/default` alone is almost always a bug in a boot script.** Write `all` for the
  machine's posture and `default` for interfaces yet to exist. Writing only the second
  hardens nothing that is currently plugged in.

Cross-machine consequence, still open at the time of writing: this fix landed in the
shared override, so `server`'s generated recipe carries it too -- but `server` was built
before it, and a regenerated recipe does not touch an already-installed
`/etc/systemd/scripts/iptables` or a running kernel. Until someone reinstalls that file
on `server` (or writes the sysctl by hand there), `server` still accepts redirects on
every interface. A shared-layer fix reaches a built machine only when something applies
it.

## A GPU probe that crashes turns into a browser with no GPU, silently

Firefox decides whether to use the GPU by forking `/usr/lib/firefox/glxtest` at startup
and reading its report back over a pipe. If that child dies, the answer is "no GPU" and
the whole session runs on software -- software compositing, and WebGL that websites see
as unaccelerated or missing. There is no error in the UI, nothing in the journal from
Firefox itself, and no pref written to record it, so a browser in this state looks
identical to a healthy one until a site refuses to load.

On `laptop` this left Firefox running nine hours with no GPU while `mpv` and Hyprland on
the same display used it normally. Three `glxtest` SIGSEGVs are on file, each in a
Firefox launched from a link in Slack; the fault is a read of `0x143` at the entry of
`pthread_mutex_lock`, a garbage mutex pointer in the forked child. The probe run by hand
succeeds 200/200 and reports the hardware correctly, which is exactly why it is
misleading to test it that way and conclude the machine is fine.

The general shapes, both worth having:

- **A working GL stack is not evidence that a given process is using it.** Every
  layer can check out -- render node present, correct group, driver bound, `glXIsDirect`
  1, hardware EGL on the X11 platform -- and the application can still be in software.
  Probe the process, not the stack.
- **Ask what the process has mapped.** The one-line answer is
  `grep -cE 'libEGL|libGLX|libgallium|/dri/' /proc/<pid>/maps`, with `ls -l /proc/<pid>/fd
  | grep dri/` as the confirmation. Zero across every process of an application that
  should be rendering means software, no matter what the stack tests say. Take a control
  from something on the same display that is known to use the GPU.
- **A crash in a forked helper is worth `coredumpctl list` before anything else.** It
  named the process, the timestamp that matched the parent's start to the second, and the
  cgroup that revealed the launch path. On a build with `--disable-debug-symbols` and no
  gdb, the journal's `ip ... in libc.so.6[<offset>,<base>+<size>]` line is still enough:
  resolve `<offset>` against `readelf -sW` on the library and the faulting function comes
  out by name.
- **Where a capability is auto-detected, prefer forcing it once the hardware is
  measured.** Same lesson as an `auto` meson feature, one layer up: `gfx.webrender.all`,
  `webgl.force-enabled` and `gfx.x11-egl.force-enabled` make acceleration independent of
  the probe surviving. Only after measuring the GPU, and only in the host layer -- on a
  genuinely blocklisted GPU these force a known-bad path.

## Killing `lfsbuild` does not kill the build, and the orphan installs without a manifest

Found on `laptop`, 2026-09-12, building qttools. An external supervisor killed the
foreground `lfsbuild` invocation for memory pressure. That did not stop the build: the
recipe runs as a `sudo` child, and killing the driver only reparented it to init, where
it carried on compiling as root. `ps -o ppid= -p <recipe pid>` read `1`, which is the
tell.

Left alone it would have finished, and that is the damaging part rather than a lucky
escape. The recipe's own `cmake --install` would have run, putting a few hundred files on
the system; but the driver that was going to run the `find -cnewer /tmp/.lfsbuild-stamp`
manifest capture, mark the step complete and clean the source tree was gone. The result
is the one state this project has no way to repair after the fact: installed files that
no manifest owns, on a system whose only package database is `lfsmaint`, whose answers
are only as good as the manifests. `lfsmaint owns` would have said nothing about them and
nothing would have looked wrong.

Two practices follow.

- **After any interrupted step, check for survivors before doing anything else.** `ps -e
  -o pid,ppid,args | grep <srcdir>`. If the recipe is still running, kill it, remove the
  source tree under `$SOURCES` and re-run the step from the driver. A few minutes of
  rebuild is much cheaper than an unowned install, and re-running is safe: the recipe
  reinstalls over itself and the manifest is captured properly the second time.
- **Detach long builds from whatever is supervising the session.** `setsid nohup
  bin/lfsbuild ... &` puts the driver in its own session, so a kill aimed at the
  foreground command cannot decapitate it and leave the build headless. The driver then
  lives long enough to write the manifest even if the thing that launched it goes away.

Note the asymmetry with the abort case above: there, the recipe died and the driver's
cleanup was skipped. Here the driver died and the recipe kept going. Both end with the
step's bookkeeping unwritten, and the manifest is the half that cannot be reconstructed.

## Standing policies

- **BLFS Recommended dependencies get installed, not just Required** -- but checked
  against what the machine is, one level deep, not chased down every recommended dep's
  own recommended deps. `vim`'s only Recommended dependency is a GTK3 desktop GUI: right
  to skip on a headless box, and the skip is recorded rather than silent.
- **Anything on the boot path is `=y`, never `=m`.** LFS installs no initramfs, so a
  module needed to reach the root filesystem is a kernel that cannot boot, and the failure
  appears only at boot time. `kernel-config-base.sh` ends with a gate that fails the build
  instead.
- **Pin the optional dependencies a recipe relies on.** A meson `feature` left at `auto`
  turns a `seq` ordering mistake into a package that builds clean and quietly lacks half
  its function -- see the pipewire/ALSA section above. Pin it to `enabled` so the build
  fails at configure time instead.
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

## A generated file keyed to an outside release needs that release in its path

`recipes/` held one generated recipe per book page, shared by every machine. That worked
exactly as long as every machine read the same book. `server` moved to LFS/BLFS 13.1 on
2026-09-07, `laptop` stayed on 13.0, and from then on whichever machine ran an extraction
last owned the tree: `laptop`'s `--check` reported 112 BLFS and 131 LFS recipes as
drifted, none of them a hand edit, all of them the other machine's book. Drift detection
is the mechanism that proves a recipe still matches its own rationale, and a permanent
112-line false positive turns it off as surely as deleting it.

Fixed 2026-09-21 by putting the release in the path -- `recipes/<family>-<ver>/<step>.sh`,
with hand-authored recipes left at the top level where no extractor writes. The general
shapes:

- **Two artifacts derived from two different inputs are two artifacts.** They were sharing
  a filename because they usually agreed, which is not the same as being the same file.
  Sharing held while both machines tracked one book and broke silently the moment one
  moved.
- **A decision that names a block by index is version-bound too.** The overrides file had
  to split the same way. Before it did, the only way for `laptop` to survive `server`'s
  bump was 16 host-level entries whose entire job was to cancel a shared decision that had
  been re-indexed -- bookkeeping that existed to work around the layout, and that deleted
  itself when the layout was fixed.
- **Suspect a false positive that never goes away.** The drift was reported honestly for
  three weeks and read as noise, because acting on it meant regenerating recipes for the
  other machine's book. A check nobody can act on gets ignored, and then the real signal
  it would have carried is gone too.
- **The migration is a `git mv`, not a regeneration, when history still holds the inputs.**
  The 13.0 tree came back byte-exact from the last commit before the bump (`9b77eca`),
  which made the whole change reviewable as a diff and needed no second copy of the books.

## A fix in the overlay is not a fix on the machine

`overlay/` and `hosts/<h>/overlay/` are deploy-time trees. Nothing in `bin/` applies
them, which means a session can reason its way to the right content, commit it, write it
up in `BUILD-REPORT.md`, and leave the running host exactly as it was.

That happened on `server`, 2026-09-21. The audit found `/boot/grub/grub.cfg` searching
for `--fs-uuid 4ed155bc-…`, an identity the partition lost when it was re-imaged. The
live file was patched to the *new* fs-UUID; an hour later the decision was reconsidered
-- a re-image mints a fresh fs-UUID every time, so the search has to key off
`--label LFSROOT`, which `mkfs.ext4 -L` writes back -- and that went into the overlay
with its reasoning. The live file was never brought forward. The report then said "now
searches `--label LFSROOT`", which was true of the repo and false of the machine, and
the host stayed one re-image away from the silent failure the audit had just removed.

- **Diff the overlay against the live tree before claiming a deploy-time file is fixed.**
  All 13 files, not the one just edited; it costs one loop and it is the only check that
  distinguishes "decided" from "deployed". Twelve matched here and the thirteenth was the
  one under discussion.
- **A live edit and an overlay edit are two separate acts.** Doing the first does not
  schedule the second, and doing the second does not imply the first. If only one has
  happened, the entry has to say which.
- **Fix the procedure, not just the file.** `BOOTSTRAP.md` step 5.3 was the real source:
  it instructed the operator to copy the overlay `grub.cfg` and then hand-patch the
  fs-UUID to whatever step 4's `mkfs` had just generated. The tracked file and the
  procedure that deploys it disagreed, and the procedure wins, every time, on the next
  machine. An identifier a human has to remember to update is the defect -- the fix is to
  leave none to update, not to document the update more clearly.

Same shape as the strip incident above, one layer out: there, a practice stated in prose
while the skill still issued the old command; here, a decision stated in a tracked file
while the procedure still issued the old hand-edit. In both cases the write-up read as
done and nothing that executes had changed.

## A carried-over review decision fails silently, and the manifest is what tells you

Root `CLAUDE.md` already says a decision names a block by index and that carrying one
across a book release is a re-read, not a copy. What it does not say is what the failure
*looks like*, and the answer is: like success.

On `server`, 2026-09-22. BLFS 13.0's nss page had four command blocks -- build, test
suite, install, p11-kit symlink -- and a `drop` on index 1 recorded that the test suite
hard-failed 564/606 tests in 20.9 minutes. BLFS 13.1 removed the test-suite block from
the page. Everything below it shifted up one, so index 1 became the install:
`cd ../dist && install -v -m755 Linux*/lib/*.so /usr/lib && ...`. The decisions had been
copied release-to-release when `overrides.json` was split per release, so "skip the
tests" silently became "skip the install".

`blfs-nss` then built NSS 3.126 from source, installed none of it, **exited 0**, and was
marked complete. It could not have reported otherwise: dropping a block is a legitimate
outcome, and every block that remained -- the build, and the p11-kit symlink -- really
did succeed. Nothing was broken, nothing was missing, and the wrong thing had been
skipped on purpose. It surfaced two steps later when Firefox's configure demanded
`nss >= 3.125` and pkg-config answered `3.120.1`, the version from the previous install
still sitting on disk.

- **The manifest file count is the detector.** `blfs-nss` captured a **one-file**
  manifest where its neighbours captured 73 (nspr), 285 (ffmpeg), 713 (mesa), 3960
  (llvm). A step that compiles for eight minutes and installs one file is not a
  plausible package. Check it after any build whose recipe was regenerated against a new
  book, and be suspicious of any manifest that shrank.
- **Compare block counts before trusting carried decisions.** For each recipe, the number
  of command blocks in the old release's generated file against the new one. Equal counts
  mean the indices still line up and the decisions are probably still aimed at what they
  name; a change means every decision on that recipe needs re-reading against the actual
  block text. Across 17 recipes regenerated for 13.1 this isolated exactly two, and both
  were real.
- **A block count can grow, too, and that is the quieter direction.** `glad` gained a
  test-suite block at index 1 in 13.1, between building the wheel and installing it. The
  existing `replace` on index 0 still landed correctly, so nothing looked wrong -- but the
  new block arrived *enabled*, because the extractor only queues a block for review when
  the surrounding prose carries "if you want" framing. A newly inserted required-looking
  step is invisible to both the decision check and the review queue.
- **Neither `--check` nor the review queue can see any of this.** Both compare the
  generated file against what the overrides say to generate. They agreed perfectly the
  whole time, because the recipe on disk *was* exactly what the decisions asked for. Zero
  drift and zero blocks awaiting review were both true and both meaningless here.
