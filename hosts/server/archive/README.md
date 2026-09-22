# `server`'s archived build records

Two build records that are no longer the live one. Nothing in `bin/` reads this
directory -- it exists so the records of real builds are not deleted, and so the
directories that *are* read describe the machine that is actually running.

Created 2026-09-21, executing the state move that `BOOTSTRAP.md` step 6 and
`hosts/server-rebuild/host.toml` had both specified since 2026-09-07 and that the
deploy never performed.

## `13.0-image/`

The records of the LFS/BLFS **13.0** system that occupied `sdb2` until it was re-imaged
on 2026-09-21. This is history, not the running machine.

| | |
|---|---|
| `manifests/` | 302 files, 105,666 unique paths |
| `completed` | 363 steps, last touched 2026-09-17 (`blfs-unixodbc`, a native build) |
| `timings.tsv` | that system's step timings |
| `logs/` | 173 build logs |

Until this move, these sat at `hosts/server/manifests/` and `hosts/server/state/` --
which is to say every tool resolving `--host server` read the **13.0** install's records
while describing a 13.1 machine. `lfsmaint verify` was only correct because the live
database had been rebuilt by hand with an explicit
`--manifests hosts/server-rebuild/manifests`.

## `server-rebuild/`

The bookkeeping of the from-scratch **13.1** chroot build that produced the image now
running: `host.toml`, the plans, and `lfsbuild-blfs.log`. It ran 2026-09-07 to 09-09 in
`hosts/server-rebuild/`, a directory that was never a second machine -- its
`packages.py`, overrides, `recipes/` and `overlay/` were all symlinks back to
`hosts/server/`. Only `state/`, `manifests/` and `logs/` were ever real there, and those
three are now `hosts/server/`'s own, which is what that directory existed to produce.

Its `state/*.json` are kept as the build's record. They are duplicates of, or older
than, `hosts/server/state/`'s current files -- with one exception worth naming, since it
is the same failure in miniature: `glfs-plan.json` here had `libglvnd` at the correct
`seq 49.8` while `hosts/server/state/` still said `127`. Regenerated natively rather
than copied.

## What is *not* archived here

`hosts/server/state/testreports/` stays where it is. Those are Chapter 8 test-suite
results for binutils, gcc and glibc -- properties of the book and the toolchain, not of
one image.
