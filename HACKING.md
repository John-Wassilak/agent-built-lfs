# Working on agent-built-lfs

The detail the README leaves out: where things are, how the sharing works, and what to do
to add a machine. `CLAUDE.md` is the same ground stated as rules, for an agent session.

## Layout

```
bin/                shared tooling: extractors, plan builder, driver, maintenance
packages/base.py    the BLFS core every machine needs, in build order
recipes/            book-derived recipes, machine-neutral. One copy for all hosts
overlay/            portable config: sshd, systemd units, dotfiles for a portable desktop
book/              the LFS and BLFS books (gitignored -- fetched, not authored)
hosts/<name>/
  host.toml         what the tooling reads, plus [hardware] as reference
  packages.py       BASE + this machine's own stack, in build order
  kernel-config.sh  bin/kernel-config-base.sh plus this machine's hardware
  recipes/          recipes bound to this hardware; shadow the shared copy by name
  overlay/          config only this machine wants: xorg.conf, grub.cfg, mpv hwdec
  review-overrides.json   review decisions that name a device, label or /boot path
  state/            plan.json, blfs-plan.json, completed, timings.tsv, index, queues
  manifests/        which files each package installed on this machine
  logs/             per-step build logs (gitignored)
  BUILD-REPORT.md   the narrative: what was built, what broke, what was decided
```

Machines currently in the repo:

| host     | what it is | status |
|----------|------------|--------|
| `server` | i5-2500K, GTX 770 on NVIDIA 470.xx, X11 + awesome, self-hosting | built, 218 BLFS steps |
| `laptop` | not audited yet | scaffold only, see `hosts/laptop/BOOTSTRAP.md` |

## Resolving the host

Every tool resolves one machine before it touches anything: `--host <name>`, else
`$LFS_HOST`, else the short hostname. On the machine being built, no flag is needed:

```
bin/lfsbuild --status                 # this machine
bin/lfsbuild --host laptop --status   # another machine's plan, from here
bin/lfshost.py                        # show every path the resolution produced
```

An unknown name is fatal rather than defaulted, because guessing would write one
machine's state into another's directory.

## The two sharing mechanisms

**Recipe shadowing.** `hosts/<h>/recipes/<step>.sh` wins over `recipes/<step>.sh`. This is
for steps whose content is bound to real hardware and cannot be derived from the book: a
proprietary driver, a CPU's microcode blob, ffmpeg's NVENC flags. `bin/lfshost.py` prints
which copy each step resolves to.

**Override merging.** For a step that *is* a book page but whose right answer is
machine-specific, the decision goes in `hosts/<h>/review-overrides.json` and is merged
over `recipes/review-overrides.json` block by block. `ch10-kernel` is the example: the
shared file keeps "menuconfig is not scriptable, run kernel-config.sh instead" and the
host supplies only the `/boot` paths. The extractor then writes the neutral candidate to
`recipes/` and the merged version to `hosts/<h>/recipes/`.

## Normal flow

```
bin/fetch-sources.sh                     # download + md5-verify the book's 92 sources
bin/extract-recipes.py --check           # would re-extraction change any recipe?
bin/extract-recipes.py                   # book HTML -> recipes/ (+ host copies)
bin/build-plan.py                        # -> hosts/<h>/state/plan.json
bin/extract-blfs.py --check              # same question for the BLFS side
bin/extract-blfs.py                      # -> hosts/<h>/state/blfs-plan.json
bin/lfsbuild --status                    # what is done, what is next
bin/lfsbuild --resume                    # LFS plan
bin/lfsbuild --blfs --resume             # BLFS plan
bin/lfsmaint db                          # rebuild the package database from this host's
                                         #   plans + manifests (needs root)
bin/lfsmaint report                      # installed packages, advisories, version drift
bin/lfs-archive --live backup.tar.zst    # restorable backup of a running system
```

Run `--check` before either extractor. It reports **drift**: a recipe on disk that is not
what the book plus the recorded decisions produce, which means someone edited it and the
edit is captured nowhere. Regenerating would discard it. The fix is to record the edit as
a review decision, or to make the step a `hand()` entry the extractor does not own.

## Adding a machine

1. `mkdir -p hosts/<name>` and write `host.toml`. Leave `arch` out unless building it
   from a machine of a different architecture.
2. Audit the hardware first and fill in `[hardware]`. Those answers decide the kernel
   config and half the package selection; guessing them costs a rebuild.
3. `packages.py`: start at `PACKAGES = list(BASE)`. Add steps with the next unused `seq`.
4. `kernel-config.sh`: source `bin/kernel-config-base.sh`, add only this machine's
   hardware, and put anything on its boot path in `EXTRA_GATE_BUILTIN`.
5. Write a `BOOTSTRAP.md` for the machine and work through it. `state/` and
   `manifests/` are created by the tools on first run -- nothing to seed.

## What makes the record auditable

The point of the override mechanism is that a decision survives re-extraction and stays
attached to its reason. Four things hold that up:

- **178 review decisions across 74 recipes**, each with a `reason` citing the book (130
  drop, 40 replace, 4 enable, 3 test, 1 defer). They live in the `*-overrides.json`
  files, never in the generated recipes, so regenerating cannot lose them.
- **`--check` on either extractor** re-derives every recipe from the book plus those
  decisions and reports any that differ.
- **The plan is regenerable.** `extract-recipes.py`, `build-plan.py` and
  `extract-blfs.py` reproduce `hosts/<host>/state/*.json` from `packages.py` plus the
  book.
- **329 packages with per-file manifests**, so `lfsmaint owns <path>` answers on a system
  with no package manager.

Every commit is co-authored and its message carries the reasoning; the commit history is
the rest of the record.

## Before you commit

Run both extractors with `--check`. Zero drift is the expected state, and a non-zero
result means a recipe on disk is no longer what the book plus the recorded decisions
produce -- someone edited a generated file and the edit is captured nowhere.

    bin/extract-recipes.py --check
    bin/extract-blfs.py --check

`bin/lfsbuild --status` and `--blfs --status` should report the counts you started with.
