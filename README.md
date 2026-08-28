# agent-built-lfs

A [Linux From Scratch](https://www.linuxfromscratch.org/lfs/) system built and maintained
by an agent. Claude Code reads the book, turns each page into a recipe, records a reasoned
decision for every command it disables or rewrites, and drives the build. The system calls
itself `claude-managed` in `/etc/os-release`, hence the name.

`server` is live: i5-2500K, GTX 770 on NVIDIA 470.xx, X11 and awesome, 133 LFS steps, 218
BLFS packages, self-hosting. `laptop` is scaffolded.

## Things to know

- Like ALFS or any automated LFS build, your real chance of success is having done a
  manual LFS build before. When something breaks, you need to know how to fix it -- or in
  the agentic case, what to tell your agent to do and what questions to ask it.
- Getting from a built system to an installed OS is up to you. I build in a local
  directory, copy it to a USB, make the USB bootable (fstab and all), boot from it, and
  keep a tarball of the built OS handy to copy onto the destination disk. What else goes on
  the USB besides LFS is your call -- at minimum get sshd running on it.
- Once booted, have your agent walk BLFS's recommended post-build configuration: a user
  with sudo access, groups, a firewall, sudo itself, SSL, and the rest.
- Along the way, have your agent scan the system and its logs for errors, cleanup that
  needs doing, misconfigurations, hardware that isn't loading, security issues. Agents like
  Claude Code are good at finding these once asked, but you have to ask.
- Point your agent at specific things to check. Video hardware acceleration matters to me,
  so I had Claude squeeze every drop out of my GPU and verify mpv was configured correctly.
  It is strong at fixing a known problem, weaker at surfacing problems on its own -- direct
  it.

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

~~Every command resolves one machine -- `--host`, else `$LFS_HOST`, else the hostname --
so no flag is needed on the box you are on. `bin/lfsbuild --status` / `--resume` / `--only
<step>` drive the build; `bin/lfsmaint owns` / `report` track what installed a file and
what has drifted; `bin/lfs-archive --live` backs up the running system.~~

The commands above are the mechanical interface. The real one is opening Claude Code in
this repo and saying what you want:

    build LFS on this machine and walk me through the deployment steps
    openssl has an advisory -- upgrade it and tell me what else needs rebuilding
    audio stopped working after the kernel rebuild, find out why
    set up the laptop, starting with the hardware audit

`CLAUDE.md` is what makes that work rather than a gamble: it tells a session how to resolve
a host, where a decision belongs, and never to edit a generated file in place. The state it
needs is all readable -- the plan, the completed list, per-package manifests, every
decision with its reason -- so a session can pick up work it did not start, and `--check`
tells it whether the tree still matches the record.

Expect to stay in the loop: it asks before anything privileged, and the hardware calls are
still yours.

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
