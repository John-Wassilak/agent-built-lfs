# agent-built-lfs

Linux From Scratch, built and maintained by an agent -- Claude Code -- across more than
one machine. The system identifies itself as `claude-managed` in `/etc/os-release`, which
is where the name comes from.

A build harness for LFS 13.0-systemd and the BLFS packages on top of it, driving several
machines from one repo. The book is the same everywhere; the hardware is not. Everything
that is the same is shared, everything that is not belongs to a host.

`PRACTICES.md` is the part worth reading if you only read one file: what turning a book
written for a human at a prompt into an unattended build actually costs. "How this was
built" at the bottom covers the agent side, including where it went wrong.

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

`PRACTICES.md` collects what the first machine's build taught, separately from the
machine it taught it on.

## How this was built

Claude Code did the work: extracting recipes from the book HTML, deciding every disabled
or rewritten block, building the plan, writing the driver and the maintenance tooling,
and the multi-host restructure. The commit history is the record -- every commit is
co-authored, and the messages carry the reasoning.

The operator made the calls an agent should not make alone: hardware, scope, and policy.
The clearest example is in `hosts/server/`, where Wayland was abandoned for X11 after the
NVIDIA 470.xx EGLStreams dead end -- recorded as an operator decision, with the
abandoned plan (`HYPRLAND-PLAN.md`) kept because it explains the gaps in the build order.

What makes the claim checkable rather than a slogan:

- **178 review decisions across 74 recipes**, each with a `reason` citing the book (130
  drop, 40 replace, 4 enable, 3 test, 1 defer). They live in the `*-overrides.json`
  files, not in the generated recipes, so re-extraction never loses them.
- **`--check` on either extractor** re-derives every recipe from the book plus those
  decisions and reports any that differ. Zero drift is the expected state, so a recipe
  cannot quietly stop matching its recorded rationale.
- **The plan is regenerable.** `extract-recipes.py`, `build-plan.py` and
  `extract-blfs.py` reproduce `hosts/<host>/state/*.json` from `packages.py` plus the
  book.
- **329 packages with per-file manifests**, so `lfsmaint owns <path>` answers on a system
  that has no package manager.

### Where the agent went wrong

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
