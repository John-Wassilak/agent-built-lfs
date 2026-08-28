# Working in this repo

One repo, several machines. Read `README.md` for the layout; this is what a session has
to get right.

## Resolve the host before touching state

Every tool in `bin/` resolves one machine (`--host`, else `$LFS_HOST`, else the hostname)
and every path it reads or writes belongs to that machine. Never hardcode a path under
`hosts/`; get it from `bin/lfshost.py`. `python3 bin/lfshost.py [--host X]` prints the
whole resolution, including which copy of a recipe each step would use.

When a question is about a machine, say which one. "the plan", "the manifests", "the
build report" are ambiguous now; `hosts/server/state/plan.json` is not.

## Shared or host: the test

Ask whether the thing is true of *any* machine running this book.

- Shared: book-derived recipes, the review decisions that record a book fact (an
  interactive command, a placeholder, a diagnostic grep that exits 1 on success), the
  generic boot path in `bin/kernel-config-base.sh`, portable dotfiles and units.
- Host: anything naming a device node, a filesystem LABEL, a GPU vendor, a CPU model, a
  `/boot` path, a specific codec. Also anything whose real content is hand-tuned past
  what a review decision can express.

If unsure, put it in the host. A shared file that is secretly machine-specific breaks the
next machine silently; a host file that turns out to be portable is a two-line move.

## Do not edit generated recipes in place

`recipes/*.sh` are generated from the book. An edit there is lost the next time the
extractor runs, and `--check` will report it as drift. The three legitimate ways to change
what a step does:

1. Record a review decision in `recipes/blfs-overrides.json` or
   `recipes/review-overrides.json` (shared), or `hosts/<h>/…` (machine-specific). Every
   decision carries a `reason` citing the book. This is the default.
2. Make it a `hand()` entry in the host's `packages.py` and write the recipe as a normal
   file. Correct when the real content is not book-plus-a-decision -- a tuned configure
   line with a long rationale, a driver BLFS does not carry.
3. For a book page whose answer is machine-specific, a host override, which generates
   `hosts/<h>/recipes/<step>.sh` alongside the neutral shared candidate.

Run `bin/extract-recipes.py --check` and `bin/extract-blfs.py --check` before any
extraction, and after changing an override. Zero drift is the expected state.

## Build order is `seq`, and `seq` is permanent

`packages.py` entries carry an explicit `seq`. Gaps are history -- a step that was
planned, numbered and dropped. Do not renumber to close a gap and do not reuse a number;
new steps take the next unused one. Keep the list sorted by `seq`.

## Record decisions where they will be found

- A build's narrative, what broke, what was measured: the host's `BUILD-REPORT.md`,
  appended to, with the date.
- Why a block is disabled or rewritten: the `reason` field of the override, not a comment
  in the generated file.
- Why a hand-authored recipe does what it does: a comment block in the recipe itself.
- Something the first machine's build taught that applies to any machine: `PRACTICES.md`.

## Tooling constraints

Python 3 standard library only, no pip, no third-party modules -- `bin/` has to run on
the LFS system itself, where there is no package index. `tomllib` is fine (stdlib since
3.11). Same for shell: nothing that is not in the LFS/BLFS closure.

The system has no package manager. `lfsmaint` is the package database, and it is only as
good as the manifests, so a step that installs files must capture one.
