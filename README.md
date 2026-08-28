# agent-built-lfs

A [Linux From Scratch](https://www.linuxfromscratch.org/lfs/) system built and maintained
by an agent. Claude Code reads the book, turns each page into a recipe, records a reasoned
decision for every command it disables or rewrites, and drives the build. Two machines run
off this one repo. The system calls itself `claude-managed` in `/etc/os-release`, which is
where the name comes from.

Right now that means `server`: an i5-2500K with a GTX 770 on the NVIDIA 470.xx driver,
running X11 and awesome, 133 LFS steps and 218 BLFS packages, self-hosting. `laptop` is
scaffolded and not built yet.

## Why

I ran LFS as a daily driver for years. Then I had kids, and I no longer have weekends to
spend babysitting a build or days to spend fixing a package that broke on upgrade. That is
the only reason I stopped, and it was always the only reason.

What changed is that Claude turned out to be genuinely good at reading a book carefully,
which is most of what LFS actually demands. Not clever -- careful, at length, without
getting bored on page 300. So I pointed it at the book and had it build the thing, with
every judgment call written down somewhere I can audit it.

The division of labour is not subtle: the agent does the reading, the extraction, the
decisions about individual commands, and the tooling. I make the calls that need someone
who knows the hardware and has to live with the machine -- which is why `server` runs X11
rather than Wayland, a call recorded as mine after the NVIDIA 470.xx dead end.

So far so good. Check back after my first real rebuild, because that is the test that
matters: not whether an agent can follow a book once, but whether the record it kept is
good enough to upgrade a package a year from now without breaking the machine.

## How to use it

Every command resolves one machine -- `--host`, else `$LFS_HOST`, else the hostname -- so
on the box you are working on, no flag is needed.

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

Recipes are generated, so before regenerating them, ask whether that would throw anything
away:

```sh
bin/extract-recipes.py --check     # zero drift is the expected state
bin/extract-blfs.py --check
```

That check is the load-bearing part of the design. It re-derives every recipe from the
book plus the recorded decisions and reports any that differ, so a recipe cannot quietly
stop matching its own written rationale. That is the failure mode that would make the
whole record worthless, and it has already happened once.

## What is in here

    bin/          the harness: extractors, plan builder, driver, package database
    recipes/      one recipe per book page, machine-neutral
    packages/     the package set every machine needs, in build order
    hosts/<name>/ one machine: its plan, state, manifests, hardware config, build log

`HACKING.md` has the full layout and how to add a machine.

## Worth reading

- **`PRACTICES.md`** -- what turning a book written for a human at a prompt into an
  unattended build actually costs. `exec` in a recipe silently truncating everything after
  it. A classifier keying off prose, which dropped 27 mandatory `make install` lines.
  Placeholders like `/dev/<xxx>` written verbatim into real config. Also where the agent
  got it wrong, which is the more useful half.
- **`hosts/server/BUILD-REPORT.md`** -- the build as it happened, dated, including the
  Wayland dead end and the detours.
- **`CLAUDE.md`** -- the rules a session has to follow here. Mostly: do not edit a
  generated file in place, and record the reason where it will be found.

## Licensing

**GPL-3.0-or-later** for everything original here; `COPYING` has the text.

One caveat. The generated recipes quote the LFS and BLFS books verbatim in their context
comments. The books permit extracting their *commands* under MIT, which is GPL-compatible
and causes no trouble, but the prose is CC BY-NC-SA 2.0, whose NonCommercial clause is
neither GPL-compatible nor free. Nothing in `bin/` incorporates it, so nothing in `bin/`
is encumbered, but the repository as distributed cannot be used commercially as a whole.
`NOTICE` explains which files fall where, credits the LFS and BLFS authors, and documents
the clean fix.
