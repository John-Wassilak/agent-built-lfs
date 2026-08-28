# agent-built-lfs

A [Linux From Scratch](https://www.linuxfromscratch.org/lfs/) system built and maintained
by an agent. Claude Code reads the book, turns each page into a recipe, records a reasoned
decision for every command it disables or rewrites, and drives the build. The system calls
itself `claude-managed` in `/etc/os-release`, hence the name.

`server` is live: i5-2500K, GTX 770 on NVIDIA 470.xx, X11 and awesome, 133 LFS steps, 218
BLFS packages, self-hosting. `laptop` is scaffolded.

## Why

I ran LFS as a daily driver for years, then had kids and lost the weekends it takes to
babysit a build or fix a package that broke on upgrade. That was the only reason I stopped.

Claude turned out to be good at reading a book carefully -- not clever, careful, at length,
without getting bored on page 300. That is most of what LFS demands. So I pointed it at the
book, with every judgment call written down where I can audit it.

The agent reads, extracts, decides individual commands, writes the tooling. I make the
calls that need someone who knows the hardware and lives with the machine: `server` runs
X11 rather than Wayland after the NVIDIA 470.xx dead end.

So far so good. Check back after my first real rebuild -- the test is not whether an agent
can follow a book once, but whether its record is good enough to upgrade a package a year
later without breaking the machine.

## The part I didn't expect

It is very good at hardware. Not the big calls, but the small tweaks that are hard to find,
that a general-purpose distro cannot ship, and that nobody would chase down by hand for one
machine.

`defconfig` pinned every core of this i5-2500K at 1600 MHz, defaulting to a governor that
waits for a process that does not exist: a measured 2.1x loss presenting as nothing but
"the machine feels slow". The BIOS misreported its audio codec slots, leaving no sound card
until a boot parameter force-probed them. Limitations too -- this Kepler card is stuck on
NVIDIA's legacy 470.xx branch, so Wayland is a dead end, established by reading the
supported-chips list rather than guessing.

Each is recorded with the measurement that justified it, which is why I still trust them a
month on. The rest are in `hosts/server/BUILD-REPORT.md`.

## How to use it

Every command resolves one machine -- `--host`, else `$LFS_HOST`, else the hostname -- so
no flag is needed on the box you are on.

```sh
bin/lfsbuild --status              # what is done, what is next
bin/lfsbuild --blfs --status       # same, for the BLFS plan
bin/lfsbuild --resume              # build everything not yet done
bin/lfsbuild --only ch08-gcc       # one step, with its own log
bin/lfsbuild --dry-run --only X    # print the generated script, run nothing

bin/lfsmaint owns /usr/bin/gcc     # which package installed a file
bin/lfsmaint report                # packages, advisories, version drift
bin/lfs-archive --live backup.tar.zst
```

### Getting the books

`book/` is not tracked: upstream content, same release for every machine. Nothing that
reads it works until it is in place, and the extractors say so rather than failing
silently.

Built against **LFS 13.0-systemd** and **BLFS 13.0-systemd** (recorded as `book` in each
`host.toml`). Fetch the chunked HTML for both from linuxfromscratch.org -- for BLFS,
`linuxfromscratch.org/blfs/downloads/13.0-systemd/`, the path its own wget-list uses --
and unpack to:

    book/13.0/           chunked LFS book: chapter04/ ... chapter11/, prologue/
    book/blfs-13.0/      chunked BLFS book: general/, postlfs/, x/, basicnet/, ...
    book/md5sums         the LFS source checksums
    book/wget-list-systemd

The extractors read only the HTML; `md5sums` and `wget-list-systemd` are for
`build-plan.py` and `fetch-sources.sh`.

### Generating the recipes

The core of it. Every recipe comes from the book plus recorded decisions -- nothing is
hand-copied, so a new book release is a re-run rather than a transcription job:

```sh
bin/extract-recipes.py             # LFS book HTML  -> recipes/
bin/extract-blfs.py                # BLFS book HTML -> recipes/, + the build plan
bin/build-plan.py                  # -> hosts/<host>/state/plan.json
```

The decisions live outside the generated recipes, in `recipes/*-overrides.json` -- 178 of
them, each with a `reason` citing the book. That separation lets the book be re-read from
scratch without losing a judgment call.

`--check` keeps it honest:

```sh
bin/extract-recipes.py --check     # zero drift is the expected state
bin/extract-blfs.py --check
```

It re-derives every recipe from the book plus the decisions and flags any that differ, so a
recipe cannot quietly stop matching its own rationale -- the failure that would make the
whole record worthless. It has happened once.

## What is in here

    bin/          the harness: extractors, plan builder, driver, package database
    recipes/      one recipe per book page, machine-neutral
    packages/     the package set every machine needs, in build order
    hosts/<name>/ one machine: its plan, state, manifests, hardware config, build log

`HACKING.md` has the full layout and how to add a machine.

## Worth reading

- **`PRACTICES.md`** -- what an unattended build costs when the book was written for a
  human at a prompt. `exec` silently truncating a recipe. A classifier keying off prose,
  dropping 27 mandatory `make install` lines. `/dev/<xxx>` written verbatim into real
  config. Also where the agent got it wrong, the more useful half.
- **`hosts/server/BUILD-REPORT.md`** -- the build as it happened, dated, Wayland dead end
  and detours included.
- **`CLAUDE.md`** -- the rules a session follows here. Mostly: never edit a generated file
  in place; record the reason where it will be found.

## Licensing

**MIT** for everything original; `LICENSE` has the text.

The generated recipes also carry the books' terms: the books permit extracting their
*commands* under MIT, but the prose quoted in the context comments is CC BY-NC-SA 2.0, so
redistributing the recipe tree means honoring attribution, ShareAlike and NonCommercial.
`NOTICE` says which files fall where, credits the LFS and BLFS authors, and explains why
the recipes are tracked rather than generated on clone.
