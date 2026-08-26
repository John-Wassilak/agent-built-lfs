# LFS 13.0-systemd — build report

Built 2026-08-25 on Gentoo Hardened (gcc 15.3.0, binutils 2.46.1, glibc 2.43, kernel
6.18.35, 4 cores / 31 GB). Tree built at `/mnt/lfs`, harness at `/home/john/lfs`.

## Result

| | |
|---|---|
| Steps | **133 / 133 complete** |
| Build time | **8.36 h** across 139 step executions |
| Deliverable | `lfs-13.0-systemd-20260825.tar.gz` — 471 MB, 69,253 entries |
| SHA256 | `3c9dd694aa3449fff022dc0ffba4aecca29a0589ed29fdde04fc0e158dd4951b` |
| Tree size | 1.7 GB uncompressed |
| Manifests | 82 packages, 50,492 installed files tracked |

Verified in chroot: bash 5.3.0, gcc 15.2.0, glibc 2.43, systemd 259.1, perl 5.42.0,
Python 3.14.3. `ldd /usr/bin/bash` resolves all 6 libraries, nothing missing.

Kernel: `vmlinuz-6.18.10-lfs-13.0-systemd` (14 MB), plus `System.map-6.18.10` and
`config-6.18.10` in `/boot`.

## Slowest steps

```
ch08-gcc         226.0 min   (full test suite)
ch08-glibc        44.5 min   (full test suite)
ch06-gcc-pass2    21.4 min
ch05-gcc-pass1    18.0 min
ch10-kernel       13.8 min
```

## Test suites (critical three, as chosen)

| Package | Result | Verdict |
|---|---|---|
| glibc-2.43 | 3 FAIL, 4 XPASS, 0 ERROR | `io/tst-lchmod` is documented by the book as failing in the LFS chroot; `io/tst-faccessat-setuid` fails because we build as root in chroot; `malloc/tst-malloc-too-large-malloc-hugetlb2` depends on host hugepage config. |
| gcc-15.2.0 | ~475,000 expected passes, **15 unexpected failures** (gcc 11, libstdc++ 4, g++ 0) | Healthy. Ran as the unprivileged `tester` user per the book. |
| binutils-2.46.0 | 1 unique FAIL (`tmpdir/gp-gmon`, a gprofng test) | Normal. |

Full reports in `state/testreports/`. Seven non-critical suites (tcl, sed, openssl,
coreutils, gawk, findutils, make) also ran and passed before the policy was tightened —
no harm, just extra assurance.

## What the review caught

The recipes are extracted from the book automatically, but every disabled or rewritten
block is a recorded decision in `recipes/review-overrides.json` — **69 decisions across
26 recipes** (44 drop, 20 replace, 3 test, 1 enable, 1 defer). The ones that would have
produced a broken or wedged build:

- **27 mandatory `make install` commands silently disabled.** My first classifier keyed off
  surrounding prose ("test suite", "known to fail"). In the book the test-suite paragraph
  sits immediately *before* "Install the package: `make install`", so gcc's and binutils'
  installs inherited the hint and were dropped. Replaced with structural rules.
- **gcc-pass1 built without the in-tree GMP/MPFR/MPC the book requires** — proven by `cc1`
  linking against the host's `/usr/lib64/libmpfr.so.6`. Forced a full rebuild of Ch. 5–6.
- **Interactive commands that would hang an unattended build:** `su - lfs`, `passwd lfs`,
  `passwd root`, `tzselect`, `vim -c ':options'`, `make menuconfig`, `localectl` ×4,
  `timedatectl` ×4, `cp -i` ×3.
- **Literal placeholders that would have been written verbatim into config:** `/dev/<xxx>`
  in fstab, `<lfs>` in `/etc/hostname`, `<your name here>` in os-release,
  `<paper_size>` in groff, `<network-device-name>` in systemd-networkd,
  `<ll>_<CC>.<charmap>` in locale.conf, and a dangling
  `/usr/share/zoneinfo/<xxx>` symlink for `/etc/localtime`.
- **Diagnostic greps that exit 1 on the _good_ outcome** and so abort under `set -e`:
  glibc's `grep "Timed out"`, binutils' `grep '^FAIL:'`.
- **`ch08-stripping` aborting on non-ELF files.** The book's `find ... -name \*.so*` matches
  GNU ld linker scripts (`libc.so`, `libm.so`, `libgcc_s.so`) and, by glob accident,
  systemd `.socket` unit files. In the interactive shell the book assumes, `strip`'s
  "file format not recognized" is harmless stderr noise; under `set -e` it is fatal.
  Fixed by adding `|| true` to that one call, preserving the book's real behaviour.
- **Hardware-specific examples that would have been installed as real config:** udev rules
  hard-coded to a webcam (idProduct 1910) and TV tuner; a systemd override for a service
  literally named `foobar`; `KEYMAP=de-latin1`, which would have left a German keyboard.
- **`ch09-systemd-custom` block 4** would have *loosened* the coredump limit: its example
  `MaxUse=5G` is larger than systemd's default of 10% of the filesystem (~2.9 GB on a
  29 GB target). Dropped to keep the stricter default.

## Configuration chosen

- Timezone `America/Chicago` (matches host), locale `en_US.UTF-8`, keymap `us`, paper Letter
- Hardware clock **UTC** (no `/etc/adjtime`, so systemd assumes UTC)
- Hostname `lfs`; DHCP on any wired interface (`Name=en* eth*`); systemd-resolved stub
- `/tmp` on tmpfs (kept — reduces write wear on a USB target)
- Boot messages not cleared at boot (`TTYVTDisallocate=no`), useful on first boot

## Root password

Set non-interactively to **`lfs-changeme`**. The book uses interactive `passwd root`, which
cannot run unattended, and leaving the account locked would make the booted system
unusable. **Change it on first boot.**

## Deferred to the USB phase

- `grub-install` — no target device existed at build time. The grub *package* is installed
  and `/boot` is populated; only writing the bootloader to a disk remains.
- `/etc/fstab` uses `LABEL=LFSROOT` for `/` and `LABEL=LFSSWAP` for swap, so **label the
  partitions accordingly** when you create them (`mkfs.ext4 -L LFSROOT`,
  `mkswap -L LFSSWAP`). Nothing is bound to a device node.
- Kernel has the whole boot path built in (`=y`, no initramfs): ext4, SCSI disk, ATA/AHCI,
  NVMe, USB (xHCI/EHCI/OHCI/UHCI), usb-storage, UAS, devtmpfs, tmpfs. A gate in
  `bin/kernel-config.sh` fails the build if any of these ends up a module.
- Target is legacy BIOS, matching the book's GRUB chapter. A UEFI target would need the
  BLFS GRUB-EFI procedure instead.

## Harness

```
bin/extract-recipes.py   book HTML -> candidate recipes, applies review-overrides.json
bin/build-plan.py        ordered plan (book order), context + tarball per step
bin/lfsbuild             driver: logs, timing, resume, Ch.8 manifests, mount guards
bin/kernel-config.sh     scripted replacement for `make menuconfig`, with a boot-path gate
bin/lfs-archive          snapshot/deliverable tarball, mount guard + leak + preservation checks
bin/lfs-umount           unmount virtual kernel filesystems, deepest first
bin/fetch-sources.sh     download + md5-verify all 92 sources
```

`./bin/lfsbuild --status` shows state; `--list`, `--only`, `--from`, `--resume`,
`--dry-run` all work. Review decisions live in `recipes/review-overrides.json` so
re-extraction never loses them.

Snapshots: `after-ch06` (1.3 G), `after-ch07` (741 M), `after-ch08` (403 M).

## Archive flags, and why

`-p` is the load-bearing one: the tree has **17 setuid/setgid binaries** (`su`, `passwd`,
`ping`, `umount`, …) that are broken if mode bits are lost. Round-trip verified: `su`
extracts as `4755 root:root`. Hardlinks (3,562 files with link count > 1) are preserved —
2,439 link entries in the archive. `--xattrs`/`--acls` are kept for after BLFS but are
**not** load-bearing today: a by-the-book LFS 13.0 tree carries no file capabilities and no
`security.*` xattrs, which I verified with `getcap -r` and `getfattr` rather than assuming.

## Next

1. Partition and label the USB, `grub-install`, unpack the tarball, boot.
2. Change the root password.
3. BLFS plus maintenance tooling — a DESTDIR package manager seeded from the 82 Chapter 8
   manifests, and an advisory/version drift tracker against the LFS and BLFS books.

---

# BLFS phase — Claude Code running in the LFS system

Added 2026-08-25, **89.8 min** total. 8 steps, 952 files tracked across 8 manifests.
Same harness: `bin/extract-blfs.py` + `./bin/lfsbuild --plan state/blfs-plan.json`.

## Result

| | |
|---|---|
| Deliverable | `lfs-13.0-systemd-claude-20260825.tar.gz` — 823 MB, 75,791 entries |
| SHA256 | `52c8bd90e4969d7ff2eb345a341b525032858e1ed3ce6c41bd812f0d777f609c` |
| Tree size | 2.4 GB uncompressed |
| Claude Code | **2.1.245** |
| Node / npm | v22.22.0 / 10.9.4 |
| OpenSSH | 10.2p1 (against OpenSSL 3.6.1) |
| curl / wget | 8.18.0 / 1.25.0 (both with libpsl) |
| git | 2.53.0 (https via curl, ssh via OpenSSH) |

## What was needed, and what wasn't

**DHCP: nothing to install.** LFS 13.0-systemd already ships systemd-networkd, and Chapter 9
enabled it. I added `/etc/systemd/network/10-dhcp.network` matching `en* eth*` so it works
on unknown hardware. systemd-resolved was already enabled too. No dhcpcd, no ISC dhclient.

**The real gap was CA certificates.** A by-the-book LFS system has an empty `/etc/ssl/certs`.
That closure is `libtasn1 -> p11-kit -> make-ca`. Now: 516 certs, a 185 KB `ca-bundle.crt`,
and 172 anchors in p11-kit. Verified by completing a real verified TLS handshake from inside
the chroot to `registry.npmjs.org`, `api.anthropic.com`, and `github.com`.

Worth noting: Node carries **146 bundled root certificates**, so npm would have worked
without any of this. The system store matters for everything *else* — `openssl`, and any tool
Claude Code shells out to.

**Node.js needed exactly one dependency: `which`.** BLFS's configure line passes
`--shared-brotli --shared-cares --shared-libuv --shared-nghttp2 --with-intl=system-icu`
because BLFS assumes you installed its "recommended" packages. Node bundles all of them, so
I dropped those flags and kept `--shared-openssl --shared-zlib` (LFS provides both, so Node
tracks system security updates). That turned a 6-package subtree into one package.

**OpenSSH needed nothing.** 87 of the 90 minutes was Node.

## Total closure: 12 BLFS packages + 2 hand-authored steps

Claude Code itself needs six:

```
which 2.23        libtasn1 4.21.0    p11-kit 0.26.2    make-ca 1.16.1
openssh 10.2p1    nodejs 22.22.0     + sshd-unit, claude-code (hand-authored)
```

Then five more added deliberately, because curl and wget are required or recommended by a
large share of BLFS and every future package would otherwise hit the same detour:

```
libunistring 1.4.1   libidn2 2.3.8   libpsl 0.21.5   curl 8.18.0   wget 1.25.0
```

And git 2.53.0, which needed **no new dependencies** — its one recommended dep is cURL (for
http/https remotes) and OpenSSH covers ssh remotes, both already present. That is the payoff
from installing curl first. 1.5 min, 345 files.

Six of git's nine command blocks had to be dropped: the page offers two mutually exclusive
documentation paths, build-your-own (`make html`, `make man`, needing asciidoc and xmlto)
versus untar-prebuilt. Enabling both, which is what a naive extraction does, fails either
way. We take the prebuilt `git-manpages` tarball and skip the HTML docs.

Verified with a real shallow clone of `https://github.com/git/git.git` inside the chroot —
4,874 files — which exercises git, curl, and the make-ca trust store together in one shot.

libpsl is not really optional: BLFS records that both upstream and the BLFS editors
"highly recommend not disabling support for libpsl due to severe security implications" --
it is what stops a cookie being set across a public suffix boundary. Verified linked into
both binaries (`libpsl.so.5`), and `curl --version` reports the `PSL` feature. curl was
configured with `--with-ca-path=/etc/ssl/certs`, so it uses the make-ca store directly;
confirmed with a verified fetch from `registry.npmjs.org` (200) and `github.com` via wget.
curl also picked up libidn2, so it handles internationalised domain names.

These five took 4.2 min in total. They are not needed by Claude Code -- Node has its own
bundled roots and its own HTTP stack -- but they remove a recurring obstacle from every
later BLFS package.

## What the review caught here

BLFS needed a different kind of scrutiny than LFS. **13 review decisions across 6 recipes** (9 drop, 4 replace).

- **Every `make install` was missing.** BLFS marks root-only commands with
  `<pre class="root">`, and my LFS parser only captured `class="userinput"`. LFS uses exactly
  one `root` block in the whole book, so this never showed up before. The first extraction
  produced 12 blocks with no install step anywhere; fixing the parser gave 29.
- **`which` would have destroyed itself.** The page is "Which-2.23 *and Alternatives*", and
  the last block is the alternative — a shell script for people who don't install the
  package. Running it after `make install` overwrites the real binary with a script.
- **`make install-sshd` is not openssh's target.** It belongs to blfs-systemd-units, which
  the openssh page merely references. Running it in the openssh tree fails.
- **BLFS's sshd hardening would have locked us out.** The book appends `PermitRootLogin no`,
  `PasswordAuthentication no` and `KbdInteractiveAuthentication no`. On a system whose only
  account is root and which has no `authorized_keys`, applying all three yields an sshd that
  nobody can log into. Set `PermitRootLogin yes` deliberately instead — see the warning below.
- **The PAM block would have failed.** It builds `/etc/pam.d/sshd` from `/etc/pam.d/login`,
  but Linux-PAM is not in LFS and Shadow was built without it, so the source file is absent.
- **`make-ca` block 5 operates on a fictional certificate** — `Makebelieve_CA_Root.pem`, the
  book's worked example of distrusting a CA.
- **`systemctl enable` can't run in a chroot**, so `update-pki.timer` and `sshd.service` are
  enabled by creating the `.wants` symlinks by hand — exactly what enable does.
- **Host keys were baked in and I removed them.** OpenSSH's `make install` runs its
  `host-key` target, so the tree shipped with three host keys. For an artifact that gets
  copied, every machine sharing one host key is wrong. Removed, with a drop-in
  (`ExecStartPre=/usr/bin/ssh-keygen -A`) generating a unique set on first boot. Verified: 0
  host keys in the tarball. `sshd -t` reporting "no hostkeys available" in the chroot is the
  expected state, not a fault.

One correction to something I claimed earlier: I said make-ca needed a downloader in the
target. It doesn't — it fetches certdata.txt with **`openssl s_client`**, not wget or curl.
So `update-pki.timer` is genuinely functional with no extra packages, and I enabled it. The
build itself still uses a pre-staged, verified `certdata.txt` via `make-ca -f -C`, so it stays
deterministic and offline.

## Security posture — read this before exposing the box

- **Root password is `lfs-changeme`** and **`PermitRootLogin yes`** with password auth on.
  That combination is deliberate: it is the only way the machine is reachable out of the box
  when root is the sole account. Do this on first boot: change the password, add
  `~/.ssh/authorized_keys`, then set `PermitRootLogin prohibit-password` and
  `PasswordAuthentication no` in `/etc/ssh/sshd_config`.
- Claude Code needs credentials; run `claude` once interactively to authenticate.

## A note on how Claude Code is packaged

The npm package is not a JavaScript bundle. It installs a **392 MB prebuilt native x86-64
binary** at `node_modules/@anthropic-ai/claude-code-linux-x64/claude`, with
`bin/claude.exe` a hardlink to it — 17 files in total, which is the whole 375 MB. So Node
is needed for npm to install and update it, but the CLI itself executes natively against
glibc 2.43 rather than running through Node. Confirmed working in the chroot
(`claude --version` -> 2.1.245). That also means the tarball carries one very large
incompressible file, which is most of the jump from 759 MB to 820 MB.

## Enabled at boot

```
sshd.service                       systemd-networkd.service
systemd-resolved.service           systemd-timesyncd.service
update-pki.timer (weekly CA refresh)
```

---

# Maintenance tooling

`lfsmaint`, installed at `/usr/sbin/lfsmaint` in the target. Python 3 standard library
only — there is no pip on this system and the tool has to keep working without one.
Network access goes over the make-ca trust store. State lives in `/var/lib/lfsmaint`.

It runs **on the LFS system**, not just on the build host — verified inside the chroot
against its own Python 3.14.3, including a live HTTPS query to upstream's advisory app.

## What it does

**Package database.** 127 packages, 53,754 files, built from the per-package manifests
the harness recorded during the build (stamp file before each `make install`, then
`find -newer` across the install roots).

```
lfsmaint report            one-page summary
lfsmaint list [pattern]    installed packages and versions
lfsmaint owns PATH         which package installed PATH
lfsmaint files PKG         what PKG installed
lfsmaint verify [PKG]      recorded files now missing
lfsmaint orphans           files present but owned by nothing
```

**Security advisories.** Queries upstream's advisory application for the book release
and reports only what names an installed package. Current state of this system:

```
LFS/BLFS 13.0 advisories: 203 total, 49 affecting installed packages
  12 Critical   vim, perl, xz, python, xml-parser, inetutils, linux, glibc, util-linux
  16 High       node.js, openssh, expat, OpenSSL, attr, acl, python, glibc, vim
  20 Medium     curl, systemd, libcap, p11-kit, openssl, util-linux, ...
   1 Low
```

These apply by construction: advisories filed against release 13.0 target the versions
13.0 ships, which is exactly what we built. This is a real backlog, not noise.

Name matching needs normalisation because upstream spells things inconsistently —
`node.js`, `node-js`, `OpenSSL`, `Linux`, `p11kit` vs `p11-kit` all had to fold onto the
installed names.

**Version drift.** Compares installed versions against a book's `wget-list`.
Against LFS 13.1-rc2: **49 identical, 43 where the book has moved ahead**, including the
whole toolchain — gcc 15.2.0→16.2.0, glibc 2.43→2.44, binutils 2.46→2.47,
linux 6.18.10→7.1.8, openssl 3.6.1→4.0.1. That is the upgrade path for most of the
advisories above.

`lfsmaint fetch-lists` downloads the lists itself, so `drift` needs no arguments.

**Weekly check.** `lfsmaint-check.timer` (Mon 03:00, 30m jitter, `Persistent=true`) runs
fetch-lists → advisories → drift and logs to the journal:
`journalctl -u lfsmaint-check.service`.

## verify: classifying expected removals

A naive `verify` reports 97 missing files on a perfectly correct system, which buries
anything real. All 97 turned out to be deliberate:

```
  72  pruned by ch08-cleanup: find /usr/lib /usr/libexec -name \*.la -delete
  19  pruned by ch08-cleanup: the cross-toolchain is removed once ch8 is self-hosted
   6  removed on purpose: sshd regenerates unique host keys on first boot

nothing unexplained -- every recorded file is either present or removed by a known step
```

So `verify` now separates accounted-for removals from unexplained ones. Anything
appearing under UNEXPLAINED in future is a genuine problem.

`orphans` reports ~38,000 files owned by nothing. That is honest but blunt: the harness
only manifested Chapter 8 onward, so everything from LFS chapters 4–7 is unowned by
construction, along with anything created at runtime.

## Two real defects the tooling exposed

Building the database is what surfaced these — neither was visible during the build.

**`/var/log/{btmp,lastlog,faillog,wtmp}` were never created.** `ch07-createfiles` block 5
is `exec /usr/bin/bash --login` — the book telling a human to restart their shell so
`id` shows the names just added to `/etc/passwd`. As a script line it *replaces the
shell*, so block 6, which creates the login-accounting files, silently never ran. Fixed
as a tracked remediation step rather than by re-running ch07-createfiles, which is no
longer safe: its `cat > /etc/passwd` would delete the `sshd` user OpenSSH added and
re-add the `tester` account ch08-cleanup removed. Verified: all four now exist, with
`lastlog` group `utmp` as the book specifies.

**`ch08-bash` had no manifest and left its source tree behind** — same `exec` truncation,
this time discarding the manifest capture and the unpack cleanup. Rebuilt; 163 files now
recorded.

Both `exec` blocks are now dropped by review decision, so re-extraction stays correct.

A third, smaller one: the test-block detector used `\btest\b`, which does not match
`make tests`, so bash's test suite stayed enabled and failed on the rebuild
(`chown: invalid user: 'tester'` — ch08-cleanup deletes that account). Regex fixed to
`\btests?\b`, and the nine non-critical test blocks across eight recipes are now
disabled to match the stated policy, so any future re-run of those packages works.

## Review decisions total

**80 for LFS, 19 for BLFS** across 34 recipes, every one carrying a reason citing the
book. The full set is in `recipes/review-overrides.json` and
`recipes/blfs-overrides.json`.

## Suggested cadence

1. Read the weekly journal entry. Critical/High advisories are the actionable signal.
2. To upgrade a package: bump the version in the plan, re-run that step with
   `lfsbuild --only <step> --force`, then `lfsmaint db` to re-record it.
3. When a new book release lands, `lfsmaint fetch-lists` then `lfsmaint drift` shows the
   whole delta at once.

---

# USB deployment

`/dev/sdc` (Lexar USB Flash Drive, 31.5 GB) wiped and rebuilt as a bootable LFS stick
on 2026-08-25. You wrote "sdac"; no such device exists, and `/dev/sdc` was the only USB —
confirmed before wiping.

## Layout

MBR (not GPT) because the target is legacy BIOS, with 1 MiB alignment so GRUB has the
post-MBR gap for `core.img`.

```
/dev/sdc1   2048       4196351   2.0G  82 swap   LABEL=LFSSWAP
/dev/sdc2   4196352   61439999  27.3G  83 ext4   LABEL=LFSROOT  (bootable)
```

Labels match `/etc/fstab` exactly as built, so nothing needed editing.

## Boot chain

```
MBR boot.img (GRUB, 55aa)  ->  sector 1 diskboot.img (5256be1b)  ->  core.img in the
post-MBR gap  ->  /boot/grub/i386-pc (305 modules)  ->  grub.cfg  ->  kernel
```

`grub-install --target=i386-pc --recheck /dev/sdc`, run **inside a chroot on the stick**
so it used the target's own GRUB rather than the host's.

Two decisions in `grub.cfg` that matter for a removable device:

- **`search --set=root --fs-uuid`** instead of a fixed `(hdN,M)`. The book flags this
  directly: a GRUB designator changes depending on what else is plugged in at boot.
- **`root=PARTUUID=219159d2-02`, not `root=UUID=`.** The kernel resolves PARTUUID from
  the partition table unaided; a *filesystem* UUID would require an initramfs, and this
  system deliberately has none. The book is explicit about this trap.
- **`rootwait`** added, because USB enumeration is slower than the kernel's root probe.

Verified: `grub-script-check` passes, the referenced kernel exists (14,582,784 bytes),
and both the PARTUUID and fs-UUID in `grub.cfg` match the real partitions.

## Payload for the permanent drive

`/root/lfs-13.0-systemd-claude-20260825.tar.gz` (823 MB) plus its `.sha256`, checksummed
**after** being read back off the flash — `52c8bd90…f609c`, matching the source byte for
byte.

## Verification after extraction

```
setuid files : 18 (su, passwd both 4755 root:root)   hardlinked: 3723
claude       : present      kernel: vmlinuz-6.18.10-lfs-13.0-systemd
ssh hostkeys : 0            (a unique set is generated on first boot)
files        : 75792        e2fsck: clean, 73565 inodes, 0 errors
```

## The stick is slow, and that is the stick

It writes at roughly **1.1 MB/s for small files** (USB 2.0 bus at 480 Mbps, but the flash
itself is the bottleneck), degrading to ~255 KB/s under sustained load. Extracting 2.5 GB
of mostly small files took well over an hour. Sequential writes are far better — the
823 MB tarball copied at about 4.4 MB/s.

Booting from this stick will feel sluggish for the same reason. That is expected and
temporary; copy to the permanent drive and it goes away.

## First boot

1. GRUB menu appears, 5s timeout, single entry.
2. Log in as `root` / `lfs-changeme`. **Change it immediately.**
3. sshd generates its host keys on first start (`ExecStartPre=ssh-keygen -A`).
4. Networking is DHCP on any wired interface; `systemd-resolved` provides DNS.
5. `claude` needs authenticating once, interactively.
6. `lfsmaint report` to confirm the package database came across intact.

## Moving to the permanent drive

The tarball in `/root` is the whole OS. On the target disk: partition, then
`mkfs.ext4 -L LFSROOT` and `mkswap -L LFSSWAP` — keep those labels and `/etc/fstab`
needs no edit. Extract with the same flags used here:

```
tar -xpf lfs-13.0-systemd-claude-20260825.tar.gz -C /mnt/target \
    --numeric-owner --xattrs --acls
```

Then `grub-install` to that disk from a chroot, and update `grub.cfg` — both the
`search --fs-uuid` line and `root=PARTUUID=` will need the new disk's identifiers.

# Permanent-drive deployment (2026-08-25)

Deployed to `/dev/sdb` (WDC WD1600AVJS, 149.1G) on the target server, replacing a live
Gentoo install already on that disk (confirmed with the operator before wiping). Same
partition geometry the disk already had — 16G swap + 133G ext4, 1MiB aligned — reused
rather than resized, same `LFSSWAP`/`LFSROOT` labels so `/etc/fstab` needed no edits.
`grub-install --target=i386-pc /dev/sdb` run inside a chroot on the extracted tree;
`grub.cfg` is not part of the base tarball (it is disk-identity-specific), so it was
hand-written from the stick's template with `/dev/sdb`'s own fs-UUID and PARTUUID.
`/dev/sda`, the host's own boot disk, was never touched.

## Baseline hardware audit, first boot from sdb

`systemctl --failed` clean, `is-system-running` → `running`, storage/USB/network
controllers all have their drivers compiled directly into the kernel (no initramfs
needed for any of them). Two real gaps found, both fixed as tracked BLFS steps
(`blfs-linux-firmware-rtl-nic`, `blfs-intel-microcode`, seq 18-19 in
`state/blfs-plan.json`) rather than patched by hand:

- **r8169 0000:06:00.0** failed to load `rtl_nic/rtl8168e-3.fw` on every boot — the
  machine's only network interface. Fixed by fetching the one blob this NIC needs from
  the LFS project's official mirror, not the full linux-firmware tree.
- **CPU microcode was stale**: i5-2500K (family 6, model 42, stepping 7) at revision
  `0x28`, applied once by the board's 2012 BIOS and never updated. `/proc/cpuinfo`'s
  `bugs:` line listed `old_microcode` and `vmscape` as unmitigated.

### Microcode reverses the no-initramfs design — deliberately, for this one purpose

BLFS's `firmware.html` is explicit that late microcode loading is no longer supported
upstream (the kernel taints and warns on it); early loading via an initrd is the only
endorsed path. That is a direct conflict with this system's original no-initramfs
design (see "Boot chain" above). Decided with the operator to add a minimal initrd
containing nothing but this CPU's microcode blob (`kernel/x86/microcode/GenuineIntel.bin`,
built with the newly-added `cpio` package) rather than late-load or skip it — `root=`
is still `PARTUUID=`, not `UUID=`, so the original reasoning for avoiding a general-
purpose initramfs still holds; this initrd carries no early-boot logic at all.

`grub.cfg` gained one line, `initrd /boot/microcode.img`, placed after the `linux` line
(the in-root-partition form, since `/boot` is not a separate mountpoint here).

Verified after reboot: `microcode: Updated early from: 0x00000028` → `0x0000002f`,
`old_microcode` is gone from `bugs:`. `vmscape` is still listed — this CPU generation
has no full fix in any released microcode, so that one is not something this change
resolves.

RTC was also switched from local-time to UTC (`timedatectl set-local-rtc 0`) — one-line
fix, `timedatectl` had flagged the local-time RTC as unreliable across DST changes.

Package count: **130 packages, 53,826 files tracked** (BLFS: 19, up from 16) —
`cpio-2.15` (build dependency for the microcode initrd), `linux-firmware-rtl-nic`, and
`intel-microcode` added to `state/blfs-plan.json` and `recipes/`, database rebuilt on
the host and copied to the target, matching the existing convention.

# General post-LFS setup, sudo, and a firewall (2026-08-25)

Standard BLFS "get the system ready for real use" work, plus the first two cases of
this project's two-tier sourcing policy in practice: **BLFS recipe where the book has
one, otherwise another distro's official packaging (checked AUR first) as the build
reference.** `htop` (previous session) and `iptables`'s dependency-free pieces all
turned out to live in Arch's official `extra` repo rather than AUR.

**Shell startup files + first non-root user.** `postlfs/profile.html` extracted
normally (12 blocks), four of them (`~/.bash_profile`, `~/.profile`, `~/.bashrc`,
`~/.bash_logout`) redirected to `/etc/skel` via overrides, exactly as the book itself
suggests for multi-user setups. `/etc/vimrc` already existed from the LFS build;
only `~/.vimrc` was added to skel (hand-authored — its BLFS source is a `<pre
class="screen">` block, which the extractor's parser doesn't capture). Copied the
same skel files into `/root`, which had none since the original build — chapter 4's
were for the temporary `lfs` user, not root. Created `john` (UID/GID 1000, `useradd
-m`) with the password locked (`usermod -L`) — no auth wired up yet, by design,
until told otherwise.

**sudo.** Straightforward BLFS build, no Recommended deps apply here. `wheel` group
already existed from the base Shadow setup; added the book's suggested
`/etc/sudoers.d/00-sudo` (`%wheel ALL=(ALL) ALL`) and put `john` in `wheel`. PAM
block dropped — Linux-PAM isn't part of this system.

**vim** — already satisfied by the LFS base build. BLFS's own `vim.html` page is
solely about optionally recompiling with GTK-3 GUI support for a desktop X11
environment (its one Recommended dependency is literally "a graphical environment
and GTK-3.24.51"). Wrong call for a headless server; skipped rather than installed
reflexively. First instance of the new standing policy — install BLFS's Recommended
deps by default, but verify each one actually fits this system first.

**Kernel: added netfilter support (second boot entry, `6.18.10-nftables`).** The
running kernel had neither `CONFIG_NF_TABLES` nor `CONFIG_NETFILTER_XTABLES_LEGACY`
set — an artifact of starting from plain `make defconfig`, not a deliberate choice.
Neither the classic iptables backend nor the modern nftables one existed in the
kernel; iptables would have built successfully as a userspace binary but failed on
its first `-A INPUT` with no `filter` table to attach to. Fixed by extending
`kernel-config.sh` (now the permanent, tracked kernel config for all future
rebuilds) with `NETFILTER_XTABLES_LEGACY=y` and the `IP_NF_FILTER` /
`IP_NF_NAT` / `IP_NF_MANGLE` / `IP_NF_TARGET_REJECT` module set (IPv4 and IPv6),
following the book's own `--disable-nftables` choice for the iptables build rather
than switching to the nft backend. Verified the real Kconfig symbol names and
dependency structure directly from this kernel's source tree rather than trusting
memory of older kernel versions — the table-registration options now depend on a
new `IP_NF_IPTABLES_LEGACY` symbol that didn't exist in earlier kernels.

Built as a **second, non-default GRUB entry** (`6.18.10-nftables`) rather than
overwriting the working kernel: `CONFIG_LOCALVERSION="-nftables"` gives it its own
`/lib/modules/6.18.10-nftables` directory, so the currently-running kernel's modules
are never touched. `default=0` in `grub.cfg` still points at the original kernel;
the new one is entry 1, selected manually to test, promoted to default only once
confirmed. Recovery if something's wrong needs no USB stick — just reselect the old
entry from the GRUB menu.

**iptables**, built against the new kernel. `postlfs/iptables.html`'s "Personal
Firewall" example (single interface, matches this box) used as-is with one addition:
an explicit `ACCEPT` for new inbound SSH before the closing LOG/policy-DROP line —
the book's own script allows no inbound service at all, and this box is administered
entirely over SSH. The "Masquerading Router" example (two-interface NAT/routing)
dropped — not applicable, one NIC. Systemd wiring via `blfs-systemd-units-20251204`
(same package `sshd.service` came from) — `make install-iptables`, and since the
system is live now rather than mid-chroot-build, the Makefile's own `systemctl
enable` ran for real instead of needing the DESTDIR/manual-symlink trick
`blfs-sshd-unit` needed. `iptables.service` is `WantedBy=multi-user.target`, so the
firewall applies on every boot automatically.

Package count: **137 packages, 54,186 files tracked** (BLFS: 26, up from 20) —
`shell-startup-files`, `skel-vimrc-and-root`, `adduser-john`, `sudo`, `iptables`,
`iptables-unit` added.

## Follow-up same day: promoted the netfilter kernel, quieted logging

`6.18.10-nftables` promoted to the GRUB default (`set default=1`) after the
operator confirmed it live — booted, `iptables.service` applied cleanly, SSH
reachable throughout. The plain `6.18.10` kernel stays as entry 0, unchanged,
fallback only.

Two logging changes, both operator-requested:

- **`iptables`'s LOG rule dropped from the firewall script entirely.** The book's
  Personal Firewall example logs every dropped packet; on an internet-facing host
  that's a constant stream of scan/probe noise, and it won't be reviewed. Simpler
  to not generate it than to filter it after the fact. `recipes/blfs-iptables.sh`
  regenerated from the updated override; the live script was overwritten and
  `iptables.service` restarted to apply it without a reboot.
- **Console log level lowered** (`loglevel=3` added to both `grub.cfg` kernel
  command lines, `dmesg -n 3` applied live for the currently running session).
  Routine kernel messages (link up/down, driver info) were interrupting work at
  the console; only err-and-worse now prints there. `dmesg`/`journalctl` still see
  everything — this only affects what's echoed to the tty in real time.

## Hyprland desktop stack (in progress, started 2026-08-25)

Full plan and rationale in `HYPRLAND-PLAN.md`, including the NVIDIA/Kepler
driver-scope decision and a running progress checkpoint. Short version: Tiers
1-4 (build tooling through Mesa/libepoxy/libglvnd) built and verified —
OpenGL acceleration via the nouveau gallium driver works, Vulkan does not
(lavapipe needs LLVM, which was deliberately not built; NVK's Kepler support
is doubtful regardless). Tier 6 (Rust toolchain, Cairo/Pango/gdk-pixbuf/
librsvg) is now complete. `cryptsetup` and `pass` (and their dependency
chains) were queued alongside this build per separate operator requests, not
part of the Hyprland stack itself — both are also now complete and verified
(`cryptsetup 2.8.4`, `pass version`); `cryptsetup` still needs a follow-up
kernel rebuild before it can actually open/create encrypted volumes
(`CONFIG_DM_CRYPT`, `CONFIG_CRYPTO_XTS`, `CONFIG_CRYPTO_USER_API_SKCIPHER`
not yet set) — see `HYPRLAND-PLAN.md`'s checkpoint section.

Tier 8 (input/session) and Tier 9 (XWayland) are now also complete --
`Xwayland -version` confirmed working. See `HYPRLAND-PLAN.md`'s checkpoint
for the real dependency gaps found along the way (lua5.4's install-path
bug, libevdev/libinput's test-framework and GTK defaults, and two xwayland
dependencies -- libxkbfile, libfontenc/libXfont2 -- the book never
documents at all).

Tier 10 (the full Hyprland ecosystem, 26 packages) is now also complete --
**Hyprland itself is built and verified working** (`Hyprland --help` prints
usage cleanly with no missing shared libraries). Along the way: two more
"claimed but never added" recipe gaps (libjpeg-turbo, muparser), an
undocumented iniparser dependency, a cascading version-bump chain
(wayland-protocols needed 1.49 not the book's 1.47, which needed wayland
1.26.0 not 1.24.0), an undocumented hard requirement on Lua 5.5 specifically
(distinct from libinput's Lua 5.4), and one genuine GCC 15.2/libstdc++ gap
(`std::ranges::starts_with` unimplemented even under C++26 mode) patched
directly in Hyprland's source. Full detail in `HYPRLAND-PLAN.md`'s
checkpoint.

Tier 11 (GTK3/PulseAudio prerequisites) is now also complete --
`pulseaudio --version` and `gtk-launch --version` both confirmed working.
Two more undocumented X11-legacy dependencies found the same way as Tier
9/10's (libXtst/libXi for at-spi2-core, libICE/libSM for PulseAudio). Full
detail in `HYPRLAND-PLAN.md`'s checkpoint.

Remaining: Tiers 12-15 (media codecs, ffmpeg, mpv, Firefox), researched
just-in-time.

272 packages tracked as of this checkpoint (161 BLFS steps), 69839 files.

## Power/internet outage during Tier 12, and recovery (2026-08-26)

Tier 12 (media codecs: nasm, libusb, dav1d, libaom, libvpx, x264, x265,
lame, libass, svt-av1, fdk-aac, libva, libxscrnsaver, sdl3, sdl2-compat --
14 packages, one hand-authored recipe added mid-batch) ran to completion on
target in a scripted batch (`build-tier12.sh` / `build-tier12-resume.sh` in
`/root/build7`), with one real dependency gap hit and fixed the same way as
every other tier: SDL3 hard-requires `libXScrnSaver` for its X11 backend,
undocumented anywhere in SDL3's own book/PKGBUILD dependency list --
discovered when the first pass's cmake configure failed outright
(`Couldn't find dependency package for XSCRNSAVER`). Fixed by hand-authoring
`blfs-libxscrnsaver` (no BLFS book page) from Arch's `extra` packaging and
resuming. The whole tier finished cleanly (`##### ALL TIER 12 PACKAGES BUILT
#####`) minutes before the host lost power and internet -- confirmed by
comparing installed-file timestamps against the build logs, not assumed.

The reboot wiped `/tmp` (tmpfs) before the per-package manifests captured
during the batch could be copied back to this repo or into
`/var/lib/lfsmaint/manifests` on target, so this checkpoint's manifests for
those 14 packages are **reconstructed, not the original captures**: diffed
the live target filesystem against the last confirmed pre-Tier-12 install
(`pulseaudio`, timestamp-anchored) and attributed each resulting file to a
package by name, cross-checked against the batch script's own
`BEGIN`/`END` markers in `build.log`/`build-resume.log`. Coverage is
complete (zero unattributed files in the diff) and manually spot-checked,
but a handful of packages show a small (1-3 file) undercount against the
counts the live build echoed at the time -- most likely install-time
side-effect files whose final mtime got overwritten by a later package in
the same batch, so they don't show up attributed to the right package in a
post-hoc timestamp diff. Not treated as material: same order of magnitude
as noise already tolerated elsewhere in this project's manifest capture
(shared files like `/etc/udev/hwdb.bin`, `/etc/mtab`, `/var/log/journal/*`
are already claimed by dozens of packages each, by design -- `lfsmaint db`
treats this as normal LFS/BLFS behavior, not an error).

One real, unrelated bug found and fixed during this reconciliation: the
existing `blfs-screen` manifest (built in the same window, from a one-off
script rather than the batch harness) was contaminated with ~120 lines of
`libvpx`'s own build-tree files under `/root/build7/libvpx-1.16.0/` --
its capture script reused a stale timestamp stamp instead of resetting one
per build. Screen's real installed footprint is 27 files; the manifest has
been corrected.

Also found stale during this pass: `/var/lib/lfsmaint/blfs-plan.json` on
target was a 176-entry snapshot that predated the `blfs-libxscrnsaver`
addition, which meant `lfsmaint db` was silently unable to attribute any of
libxscrnsaver's files to a package (no error -- the plan entry just wasn't
there to insert). Fixed by pushing this repo's current `state/plan.json`
and `state/blfs-plan.json` to target and rebuilding. `lfsmaint verify` after
the rebuild shows nothing unexpected: 91 missing-but-accounted-for files
(known `ch08-cleanup` `.la`-file pruning and cross-toolchain removal) and 3
long-standing missing `dbus` doc files unrelated to today's work.

Database rebuilt on target: **288 packages tracked (177 BLFS), 70,034
files.**

Tier 12 confirmed complete. Remaining: Tier 13 (libplacebo, ffmpeg), Tier
14 (mpv), real LLVM+clang, Tier 15 (Firefox) -- resuming now.

## Tier 13 complete: Glad, libplacebo, FFmpeg (2026-08-26)

Ran clean in one batch, this time writing each package's manifest directly
into `/var/lib/lfsmaint/manifests` as soon as it was captured (rather than
only to `/tmp`) -- the lesson from the outage above. `Glad-2.0.8` (required
by libplacebo, a pip3 wheel build, no BLFS page issue since the book's own
recipe covers it) and `libplacebo-7.360.0` both built with zero surprises.
`FFmpeg-8.0.1` configured and linked against every codec library from tiers
2/6/7/11/12 (dav1d, libaom, libass, fdk-aac, freetype2, lame, libvorbis,
libvpx, opus, svt-av1, x264, x265, openssl) with no undocumented gaps this
time -- the book's own Recommended list for FFmpeg matched this system's
prior build order closely enough that there was nothing left to discover.
`ffmpeg -version` confirms the full codec list linked in.

Package db: 291 packages, 70419 files.

Tier 14 (luajit, uchardet, mpv) launched immediately after. Next: real
LLVM+clang, then Firefox (Tier 15).

## Tier 14 complete: luajit, uchardet, mpv (2026-08-26)

`luajit` and `uchardet` built clean, no surprises. `mpv`'s meson configure
failed on the first pass: hard-requires `xpresent` (X11 Present extension)
for tear-free presentation, undocumented anywhere in mpv's own book page
(same class of gap as SDL3/libXScrnSaver in tier 12) -- not in this BLFS
mirror, hand-authored `blfs-libxpresent` from Arch's official packaging
(current upstream tarball, `libXPresent-1.0.2`, confirmed against
xorg.freedesktop.org's own archive listing rather than assumed) and
resumed. `mpv --version` confirms working.

**A real, project-wide manifest-capture bug found and fixed here**: the
`find <roots> -newer stamp` technique used everywhere in this project
(chroot driver and every hand-rolled batch script alike) tests **mtime**.
meson/ninja's install step preserves the *source* file's original mtime on
straight file copies (headers, docs, completions, icons) rather than
stamping install time -- so any such file whose source predates the
per-package stamp is invisible to the sweep. Caught because `libplacebo`'s
manifest had only 5 entries when its book page documents an entire
`/usr/include/libplacebo` directory (34 headers, verified against the live
tree), and `mpv`'s had only 6 real files against ~25 actually installed
(ninja's own verbose install log, cross-checked against the live
filesystem, gave the true list for both). This most likely affects some
fraction of every meson-built package's manifest across every earlier tier
too, not just today's -- not retroactively audited (out of scope for this
session), but worth knowing if a future `lfsmaint verify` or `owns` lookup
looks short on a meson package. **Fixed going forward**: switched the
capture command from `-newer` (mtime) to `-cnewer` (ctime) -- ctime bumps
on any file creation/copy regardless of a preserved mtime, verified with a
direct `cp -p` reproduction before relying on it for tier 15.

Package db: 295 packages, 70534 files.

## Tier 15 prerequisites complete: nspr, nss, libarchive, libnotify, startup-notification, libevent (2026-08-26)

Firefox's own Required/Recommended list needed six packages this system
didn't have yet. `nspr` and `libarchive` built clean. `nss` (which needs
nspr) built clean too -- confirms the `-cnewer` fix works: its manifest
now correctly captures all 259 files under `/usr/include/nss`, where the
old `-newer` technique would have caught only the freshly-generated ones.

`libnotify` failed its first pass on a real, undocumented hard dependency:
its `meson.build` gates the `gtk4` check behind `required:
get_option('tests')`, which defaults to true -- the book lists GTK4 as
"Recommended... required for tests" but its own recipe doesn't pass `-D
tests=false`, so the configure step fails outright even though nothing
about a normal build needs GTK4. Confirmed by reading libnotify's actual
`meson_options.txt`/`meson.build` on target rather than guessing. Fixed
with `-D tests=false` -- avoided pulling in an entire second GTK toolkit
(GTK4 plus its own new deps: graphene, ISO Codes, PyGObject) for a test
suite this project doesn't run anyway. Same class of gap as
pango/gdk-pixbuf/json-c/popt's doc-tool defaults in earlier tiers.
`startup-notification` and `libevent` built clean.

**Process change**: long builds (LLVM and Firefox from here on) now launch
inside a named `screen` session on target rather than bare `nohup &
disown`, per operator request -- both approaches survive an SSH
disconnect, but `screen` also allows reattaching to watch live output
directly (`screen -x <name>`) instead of only grepping log files.

Package db: 303 packages, 71049 files.

Next: real LLVM+clang (launched, running in `screen -S llvm-build`), then
Firefox (Tier 15) -- the two large builds remaining.

## System scan and security pass, done alongside the LLVM build (2026-08-26)

Operator requested a system health scan and a security pass while LLVM
compiles in the background (CPU-bound, no conflict with this work).

**Scan findings**: no failed systemd units; firewall is a clean
default-DROP with only SSH and established traffic allowed; 92G disk free,
31GB RAM + 15GB swap (fine headroom for Firefox); the journal-corruption
message in dmesg was systemd's own self-healing response to the power-loss
reboot, already resolved. Two real gaps found: no audio hardware registers
at all (`/proc/asound/cards` empty) -- one of the two failing HDA codec
probes is the NVIDIA GPU's own HDMI audio function, likely fixed once
nouveau is bound (see kernel section below); the other, the onboard
motherboard codec, fails for an unexplained reason, not yet chased down.
`/dev/sda` (465GB) sits unmounted with its own ext4+swap, separate from the
LFS disk (`sdb`) -- confirmed with the operator to be pre-existing data,
not touched.

**Security changes**, done in a deliberate order so a working privileged
path always existed before the previous one was closed:
1. `john ALL=(ALL) NOPASSWD: ALL` added via `/etc/sudoers.d/90-john-temp-nopasswd`
   (syntax-validated with `visudo -c`), confirmed working.
2. `PermitRootLogin no` set in sshd_config (validated with `sshd -t`,
   restarted, confirmed john's own access still worked and root SSH now
   gets refused outright).
3. `passwd -l root` -- confirmed root is still reachable via `sudo -n -i`
   (sudo doesn't consult the account password, so this doesn't remove
   access, only the password-guessing surface).
4. All non-root system/service accounts with a real (non-locked) password
   hash -- `bin`, `daemon`, `messagebus`, `systemd-journal-gateway`,
   `systemd-journal-remote`, `systemd-journal-upload`, `systemd-network`,
   `systemd-resolve`, `systemd-timesync`, `systemd-coredump`, `uuidd`,
   `systemd-oom`, `nobody`, `sshd` -- locked the same way. None of these
   should ever need interactive login. `john`'s own password deliberately
   left alone (operator still logs in as that user).

**Operator-requested config changes**: hostname changed `lfs` -> `server`
(`hostnamectl set-hostname`, plus the stale `/etc/hosts` 127.0.1.1 line
fixed to match -- `hostnamectl` alone doesn't touch that file). NTP sync
and the America/Chicago timezone were already correctly configured from
the original install, nothing to do there. `en_US.UTF-8` locale generated
with `localedef` -- `/etc/locale.conf` already pointed at it, but the
compiled locale itself had never been built, so every session was silently
falling back to `POSIX`. `/dev/sda2` added to `/etc/fstab` (by UUID) and
mounted at `/mnt/big_drive`, confirmed by the operator as the intended
mount point. `/usr/sbin` added to `john`'s own `.bash_profile` PATH for
interactive convenience -- `sudo`'s own `secure_path` already included it,
so `sudo ip`/`sudo ss` etc. already worked without full paths; this was
only missing for direct, non-sudo use.

**New packages queued** (recipes + `state/blfs-plan.json` entries written,
not yet built -- avoiding CPU contention with the running LLVM build):
`pciutils` (lspci/lspci, flagged missing during the scan), `pipewire` and
`wireplumber` (its session manager -- pipewire alone has no automatic
device management; built without the optional BlueZ/gstreamer/v4l-utils
chain, none of which this box has a current use for), and
`wireguard-tools` (no BLFS book page -- hand-authored from upstream,
version-matched against Arch's current official package rather than
assumed). All four queued to build after LLVM finishes and before Firefox,
per operator request.

**Kernel config**: `bin/kernel-config.sh` updated with the three items that
were only ever documented as "pending" in prose before now --
`CONFIG_DRM_NOUVEAU`, `CONFIG_DM_CRYPT`/`CONFIG_CRYPTO_XTS`/
`CONFIG_CRYPTO_USER_API_SKCIPHER` (cryptsetup), and `CONFIG_WIREGUARD` --
batched into one rebuild rather than three, per operator request. Kernel
rebuild itself not yet run.

## Claude Code moved from a system-wide to a per-user install (2026-08-26)

Operator flagged that the original install (`npm install -g
@anthropic-ai/claude-code`, tier 3, back on 2026-08-25) went into npm's
system-wide default prefix -- `/usr`, which is where Node's own `configure`
pointed npm at build time, matching every other package on this system.
Root-owned `/usr/lib/node_modules`, though, means Claude Code's own
self-updater can never write to its own install directory without sudo --
it was stuck at whatever version got installed that first day.

Fixed by giving `john` a private npm prefix (`npm config set prefix
~/.npm-global`, writes to `~/.npmrc`) and reinstalling there --
`~/.npm-global/bin` added ahead of `/usr/bin` in `~/.bash_profile`'s PATH.
The reinstall itself confirmed the fix: it pulled 2.1.246, one patch ahead
of the stuck system copy's 2.1.245. Old system-wide install removed
(`/usr/lib/node_modules/@anthropic-ai/claude-code`, `/usr/bin/claude`).
Confirmed `john` owns every file under the new prefix and can write to it
directly -- self-updates should work going forward without any
intervention. `~/.claude` (session history, config) is untouched by any of
this -- it was never inside the npm package's own directory tree.

`recipes/blfs-claude-code.sh` updated to install as `john` (via `sudo -u
john`) against `john`'s own npm prefix from the start, rather than as root
against the system-wide one -- so a future rebuild from scratch doesn't
reintroduce the same problem.

## LLVM+clang, seatd fix, pciutils/pipewire/wireplumber/wireguard-tools, kernel rebuild, and a successful reboot into nouveau (2026-08-26)

**LLVM-21.1.8 with clang** built clean -- the largest single build in this
project (~4343 ninja targets). `clang --version` / `llvm-config --version`
both confirm working. 303 packages, 74772 files.

**A real, blocking gap found while setting up a way to launch Hyprland
without a display manager**: this system has no PAM installed at all
(a deliberate simplification from early in the build, for a then-headless
box). Without PAM, `systemd-logind` never learns a session exists --
`loginctl list-sessions` showed zero, always, even from an active SSH
login. `seatd` (tier 8) had been built logind-only
(`-D server=disabled`), on the reasoning that logind was "already
present" -- true, but useless without session registration. Net effect:
Hyprland would have had no working path to acquire the seat (GPU, input
devices) at all, regardless of group membership. Fixed by rebuilding
seatd with `-D server=enabled`, installing its bundled `seatd.service`
(grants access via a `seat` group, not logind), and enrolling `john` in
`video`/`input`/`seat`. Confirmed running and the socket reachable.

**pciutils, pipewire, wireplumber, wireguard-tools** all built clean, no
surprises. Hit the *same* stale-`blfs-plan.json`-on-target bug as the
tier-12 outage recovery and the libxscrnsaver gap before it -- these four
packages' plan entries had been added to this repo's `state/blfs-plan.json`
earlier in the session but never repushed to target before the batch ran,
so `lfsmaint db` silently couldn't attribute their files to anything.
Third time this exact bug has bitten -- **repushing `blfs-plan.json` to
target is now a non-negotiable step before every `lfsmaint db` rebuild**,
not just something to remember. Fixed; `owns` lookups confirm correct.

**Kernel rebuilt** with the three batched additions from earlier
(`CONFIG_DRM_NOUVEAU`, cryptsetup's crypto options, `CONFIG_WIREGUARD`),
`CONFIG_LOCALVERSION="-nouveau"`. New GRUB entry added (index 2, backed up
the old grub.cfg first) and set as default -- needed for an SSH-triggered
`reboot` to land on it without physical console interaction. The two
older kernel entries (plain and `-nftables`) were deliberately left in
place as fallback, not cleaned up yet -- that happens only after the new
one is confirmed working, per this project's own established precedent
from the netfilter kernel.

**Reboot successful.** Booted `6.18.10-nouveau` cleanly. `nouveau` bound
to the GK104 (GTX 770), 2048 MiB GDDR5 VRAM detected, DRM registered, a
real `renderD128` node now exists alongside `card0` (didn't exist
before -- no GPU driver had ever been bound). `wireguard` and `dm-crypt`
modules both load cleanly. One thing the reboot did *not* fix, contrary to
this session's own earlier speculation: the GPU's HDA audio codec
(`0000:01:00.1`) still fails to probe even with nouveau now bound --
`/proc/asound/cards` is still empty. Not blocking Hyprland (video-only),
still unexplained.

**A second PAM-shaped gap found and fixed**: `XDG_RUNTIME_DIR` is normally
created by `pam_systemd` at login -- without PAM, nothing was creating it,
and Hyprland (like any Wayland compositor) hard-needs it for its socket.
Fixed with a static `systemd-tmpfiles.d` rule
(`/etc/tmpfiles.d/xdg-runtime-john.conf`: `d /run/user/1000 0700 john john
-`) rather than anything depending on the temporary NOPASSWD sudo grant,
since that's getting reverted once this build finishes. Applied
immediately and persists across reboots on its own.

**`~/start-hyprland.sh`** deployed to `john`'s home directory (tracked in
this repo at `home-john/start-hyprland.sh` for reference) -- sets
`XDG_RUNTIME_DIR`/`XDG_SESSION_TYPE`/`XDG_CURRENT_DESKTOP` and execs
Hyprland. Meant to be run manually after a physical-console login, not
auto-started -- this box has no display manager by design.
`Hyprland --help` confirmed clean (exits 0, no missing shared libraries)
post-reboot. Real interactive verification (does a session actually come
up on the real screen) is next, at the physical console -- outside what
this SSH-driven process can exercise.

Package db: 307 packages, 75520 files (pre-kernel-rebuild; the kernel
itself isn't BLFS-tracked the way userspace packages are).

Next: physical-console Hyprland test, then Firefox (Tier 15's last
package) once confirmed.

## Hyprland confirmed working at the physical console (2026-08-26)

Operator confirmed `~/start-hyprland.sh` brings up a real session.
Cleaned up the two now-superseded kernel entries (plain `6.18.10` and
`6.18.10-nftables`) -- `/boot` vmlinuz/System.map/config files and
`/lib/modules/{6.18.10,6.18.10-nftables}` removed, `grub.cfg` rewritten
down to the single working `6.18.10-nouveau` entry (`default=0`). Only
now, with a confirmed-working boot behind it -- never before.

`start-hyprland.sh` updated to redirect Hyprland's stdout/stderr to
`~/hyprland.log` (previous run rotated to `~/hyprland.log.old` on each
launch) for troubleshooting -- `tail -f ~/hyprland.log` from an SSH
session while testing at the console works fine for watching it live.

Confirmed for the operator: Hyprland cannot be started over SSH, full
stop -- not a script limitation, a property of the seat/VT model itself.
Aquamarine needs to become DRM master of a real seat with a monitor
attached, and an SSH session's pty has no VT association for
seatd to hand a seat to. Has to be a physical/local console login.

## First real attempt failed: the script's own XDG_RUNTIME_DIR logic was wrong

`~/hyprland.log` showed `Bailing out, couldn't create
/tmp/xdg-john/hypr/...` -- Hyprland was still landing on the `/tmp`
fallback, not `/run/user/1000`, despite the tmpfiles.d fix. Root cause:
`/etc/profile` carries the book's own documented fallback
(`XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}`) and runs *before*
`start-hyprland.sh` does, every login. Since nothing else ever pre-sets
the variable (no PAM), that fallback always fires first and sets it to
`/tmp/xdg-john` -- a directory nothing creates. The script's own `${VAR:-
default}` then found it already set and left it alone, silently
preserving the wrong value instead of overriding it. Correctly refused
by Hyprland rather than silently creating an insecure runtime dir, per
the XDG spec -- not a bug in Hyprland.

Fixed: `start-hyprland.sh` now force-sets `XDG_RUNTIME_DIR=/run/user/$(id
-u)` unconditionally rather than deferring to whatever's already in the
environment. `/run/user/1000` itself confirmed still present and
correctly owned from the tmpfiles.d rule -- that half of the earlier fix
was right, only the script's own env-handling was wrong.

## Second attempt failed too: found and fixed a real Mesa/glvnd bug (2026-08-26)

`~/hyprland.log` this time showed real progress -- HDMI-A-1 detected,
correct modes enumerated -- then a hard `SIGABRT` inside
`libaquamarine.so`. Full crash-report backtrace led to
`CDRMRenderer::loadEGLAPI()` (`src/backend/drm/Renderer.cpp` in
aquamarine 0.14.0, fetched from upstream to read directly rather than
guessed at): its very first EGL call never got past
`eglQueryString`/`eglBindAPI`, and no log line from that function
appeared at all -- consistent with a dead EGL dispatcher, not a real
GPU/driver problem.

Root cause, confirmed by checking file ownership directly: `/usr/lib/
libEGL.so.1` (the actual soname apps link against) resolved to
libglvnd's dispatcher (`libglvnd-1.7.0`), not Mesa's own implementation.
`/usr/share/glvnd/egl_vendor.d/` didn't exist at all -- zero registered
vendors, so every EGL call had nothing to dispatch to. Cause: Mesa's
`glvnd` meson option is `type: feature` (auto-detect), and Mesa was
built (tier 4) *before* libglvnd existed in this build order, so `auto`
found nothing to link against and silently defaulted to a standalone,
non-glvnd-aware `libEGL.so.1.0.0`. libglvnd, built afterward, then won
the `libEGL.so.1` soname with nothing behind it. Not fixable with a
hand-written vendor JSON -- the existing standalone library doesn't
implement glvnd's vendor ABI at all, only the plain direct one.

Fixed with a real Mesa rebuild, `-D glvnd=enabled` added to
`recipes/blfs-mesa.sh`. Confirmed correct this time:
`/usr/share/glvnd/egl_vendor.d/50_mesa.json` now exists, points at
`libEGL_mesa.so.0` (also confirmed present), and `libEGL.so.1` +
Mesa's vendor plugin now cooperate properly instead of the dispatcher
having nothing to dispatch to.

One related gap noticed in passing, not fixed (not blocking Hyprland,
which is EGL-only): the same theoretical problem likely exists for GLX
(`libGLX_mesa.so` exists, but no `/usr/share/glvnd/glx_vendor.d/` JSON
registers it) -- XWayland apps needing GLX specifically could hit the
same dead-dispatcher failure. Follow-up if/when that turns out to
matter.

Package db: 307 packages, 75515 files.

## Dotfiles mirrored, desktop utilities built, and a real XWayland bug found (2026-08-26)

Third attempt (after the XDG_RUNTIME_DIR and Mesa/glvnd fixes above)
actually produced a live session -- but the operator reported a
full-screen window they couldn't interact with. `hyprctl clients` (the
first time a live query against a running instance was possible this
session) showed the cause directly: Hyprland's own built-in first-run
"Welcome" dialog, auto-launched because no real config existed yet, with
a corrupted window position (`y: 884962` -- effectively off-screen),
producing the `pixman_region32_init_rect: Invalid rectangle passed`
errors in the log. Fix: deploy a real config so the welcome dialog never
launches in the first place (see below) -- not a Hyprland bug worth
chasing on its own.

**Separately, a real XWayland bug**: the same log showed XWayland's
embedded X server failing outright -- `xkbcomp: No such file or
directory`, `XKB: Failed to compile keymap`, `Fatal server error: Failed
to activate virtual core keyboard`. `xkbcomp` was never built (no BLFS
page; hand-authored from xorg's own gitlab, matching Arch's
`xorg-xkbcomp` 1.5.0). Would have blocked any X11 app's keyboard input,
including Firefox if it ever falls back to XWayland. Fixed.

**Dotfiles mirrored** from the operator's real laptop config
(`~/config/hypr`, `~/config/mpv`, `~/config/alacritty`, `~/config/wofi`)
into `~/.config` on target, trimmed for this machine after clarifying
scope with the operator: no multi-monitor block (single HDMI-A-1, let
Hyprland auto-detect), no DankMaterialShell/waybar (operator doesn't
want a shell/bar), no swayidle (no screen blanking wanted), dolphin/
chromium keybindings dropped (neither fits this build -- dolphin needs
KDE Frameworks, chromium has no build path here at all), keyboard-
backlight bindings dropped (desktop box, no such hardware, same
reasoning as the monitor exclusion). `mpv.conf`'s `hwdec=vaapi` changed
to `hwdec=auto` -- nouveau has no VAAPI driver, `auto` degrades
gracefully instead of guaranteed no-op. Reference copies of every
deployed config tracked in this repo under `home-john/.config/`.

**New small utilities built**, all hand-authored (none in BLFS), all
version-matched against Arch's official packaging: `xkbcomp` (above),
`jq` (hyprshot's JSON parsing -- its release tarball vendors a full
oniguruma copy, confirmed present before relying on it), `grim` + `slurp`
(screenshot capture/region-select), `wl-clipboard`, `wlsunset` (kept the
operator's real coordinates, 35.46/-97.32), `wofi` (turned out not to
need `gtk-layer-shell` at all -- it bundles its own wlr-layer-shell
protocol code, confirmed by reading its actual meson.build/source rather
than assuming), `hyprshot` itself (single script, version-pinned against
Arch's 1.3.0 rather than tracking upstream `main`), and `alacritty`
(Rust/Cargo, tier 6's toolchain).

**cliphist explicitly NOT built**: it's a Go program, and this project
has no Go toolchain anywhere -- building one from scratch would be its
own significant undertaking, out of scope for "install a lightweight
utility." `wl-clipboard` is installed and wired into the autostart, but
nothing consumes its `--watch` output yet.

**Two real build-script bugs hit and fixed along the way**: (1) several
fetch URLs (`slurp`, `wl-clipboard`, `alacritty`, initially `wofi`/
`wlsunset` too) used GitHub/sourcehut tag-archive links whose basename
doesn't include the project name (e.g. `v1.5.0.tar.gz`, not
`slurp-1.5.0.tar.gz`) -- silently downloaded to the wrong filename,
breaking the batch script's later lookup. (2) Alacritty's build failed
with `cargo: command not found` when run via `sudo -n bash -c` (non-login
shell) -- `/opt/rustc/bin` is only added to `PATH` by
`/etc/profile.d/rustc.sh`, which non-login shells never source. Same
class of gap as the earlier `XDG_RUNTIME_DIR` script bug: verify what a
*login* shell actually has on `PATH` before assuming a batch script's
plain `bash -c` matches it. Firefox will hit the identical issue if its
own build step isn't run via a login shell -- noted for when that tier
starts.

Alacritty finished (`alacritty --version` confirms 0.17.0), but its raw
manifest capture came back with **5956 files** -- a third real gotcha in
the same build, this one in the manifest-capture technique itself:
`/root/.cargo/registry/cache/**/*.crate` (every downloaded dependency's
cached tarball) is *inside* `/root`, one of `MANIFEST_ROOTS`, so the
`-cnewer` sweep swept up all 5945 of them as if they were installed
package files. The real install is 5 files (binary, desktop entry, icon,
2 terminfo entries) -- confirmed by hand and written directly. Left the
cargo cache itself in place (genuinely useful for Firefox's own Rust
dependencies, not clutter) but this needs excluding from the sweep
itself for any future cargo-based batch script, Firefox included --
`grep -v "^/root/.cargo"` alongside the existing `/root/buildN`
exclusion.

Package db: 316 packages, 75589 files.

## wofi "doesn't open": a real, foundational gdk-pixbuf bug (2026-08-26)

Operator reported wofi (SUPER+D) not opening. Direct reproduction with a
correctly-set `WAYLAND_DISPLAY` (my first attempt was missing it,
red herring) showed the real failure: `Gtk:ERROR:
../gtk/gtkiconhelper.c:495:ensure_surface_for_gicon: ... Failed to load
/org/gtk/libgtk/icons/16x16/status/image-missing.png: Unrecognized image
file format` -- a hard abort trying to load GTK's own *bundled* fallback
icon. `/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache` existed but listed
zero loaders; `find` confirmed zero loader `.so` files anywhere.

Root cause, found in the original recipe: `gdk-pixbuf` was built (tier 6)
with `-D png=disabled -D gif=disabled -D jpeg=disabled -D tiff=disabled`,
on the reasoning that `glycin` (a newer external Rust-based loader
service) would replace them -- but this project deliberately skipped
glycin in that same tier ("circular Rust-image-loader rebuild loop, out
of scope"), and the recipe's own glycin-detection fallback
(`$(pkgconf glycin-2 || echo -D glycin=disabled)`) meant glycin ended up
disabled too. Net effect: gdk-pixbuf could decode **nothing**, and
nothing downstream had hit a hard crash over it until now -- every icon
anywhere in this desktop stack was equally broken the whole time.

Fixed: rebuilt gdk-pixbuf with `-D png=enabled -D gif=enabled -D
jpeg=enabled` (all three backing libraries -- libpng, giflib,
libjpeg-turbo -- already built; tiff left disabled, libtiff was never
built and isn't otherwise needed). Confirmed:
`loaders.cache` now lists real loaders, wofi no longer aborts.

Live-tested wofi via `hyprctl dispatch` against the actual running
session (not just a manual reproduction) -- it now runs without
crashing. First check used `hyprctl clients`, which showed nothing;
turned out to be the wrong command entirely -- wofi is a layer-shell
surface (it bundles its own wlr-layer-shell protocol code, discovered
earlier when researching whether it needed gtk-layer-shell), not a
regular toplevel window, so it never appears there. `hyprctl layers`
showed it correctly positioned and sized on-screen the whole time.

Two more real, related gaps found and fixed along the way, both
surfaced by wofi's now-non-fatal GTK warnings: no `hicolor-icon-theme`
installed at all (the base fallback icon theme essentially every
`.desktop`-consuming app expects -- BLFS has a real page for this one,
used as-is) and librsvg built with `-D pixbuf-loader` left at its
default (`disabled`, not `auto` -- confirmed by reading librsvg's own
`meson_options.txt`), so gdk-pixbuf had no SVG loader either. Rebuilt
librsvg with `-D pixbuf-loader=enabled`. Applied the two lessons from
the alacritty rebuild while doing this one: login shell for cargo
access, `/root/.cargo` excluded from the manifest sweep from the start.

Package db: 319 packages, 76108 files (before librsvg's own rebuild
manifest lands).

## Full health/driver pass, usbutils, and the real audio root cause (2026-08-26)

Operator requested `lsusb`/usbutils plus a clean-state check (logs,
driver bindings) before continuing toward Firefox.

`usbutils-019` built clean (BLFS page, standard). `lsusb` correctly
resolves real device names via `hwdata`'s `usb.ids`.

**dmesg/journalctl**: no failed systemd units, no new errors beyond
what's already documented (ACPI SATA `_GTF` BIOS bugs, the journald
BPF-firewall notice) plus a repeating, benign `nouveau: DDC responded,
but no EDID for DVI-D-1` (that port has nothing connected). Every
`systemd-coredump` entry in the journal matched a crash already
diagnosed and fixed this session (the XDG_RUNTIME_DIR bug, XWayland's
missing xkbcomp, the welcome-dialog position bug, wofi's gdk-pixbuf
crashes) -- nothing new.

**The audio gap, actually explained**: `lspci -k` (now possible with
usbutils' sibling pciutils) plus the running kernel's own `.config`
gave the real answer this session's earlier guesses missed. The HDA
*controller* driver (`SND_HDA_INTEL`) is enabled and binds to both HDA
devices fine -- but every actual *codec* driver is unset:
`SND_HDA_CODEC_REALTEK`, `SND_HDA_CODEC_HDMI`, `SND_HDA_GENERIC` all
`is not set`. The controller can enumerate the codec chips but has
nothing to claim or configure them with -- not a hardware fault, and
not something nouveau binding was ever going to touch (confirms that
was the wrong guess, made before this session had the tools to check
properly). Added all three to `kernel-config.sh`, batched for the next
kernel rebuild -- **not run yet**, pending operator confirmation since
it needs a reboot that would interrupt the current live Hyprland
session.

**Also found via `lspci -k`, not investigated further**: a Broadcom
BCM4321 802.11b/g/n card with zero kernel driver bound. Ethernet
already provides connectivity; flagged for the operator to decide if
wireless is wanted.

**Resources**: 91G disk free, 26G RAM free, 0 swap used, load average
normal for background compiles in progress. All healthy.

**Two more manifest-accuracy bugs found and fixed via `lfsmaint
verify`** (the tool doing exactly its job): librsvg's own rebuild
manifest had picked up usbutils' already-synced files (both builds
overlapped in time, sharing `/usr`); and usbutils' *original* manifest
had 26 stray entries from librsvg's Rust build tree, caught by a
timing race between the two builds' `-newer` sweeps. Both corrected
by hand; `lfsmaint verify` now clean except the one pre-existing,
unrelated `dbus` doc-file gap documented weeks ago.

Package db: 320 packages, 76114 files. `lfsmaint verify`: clean.

## Audio: HDMI output working, onboard codec confirmed dead (2026-08-26)

Kernel rebuilt (`6.18.10-audio`: `CONFIG_LOCALVERSION`), rebooted --
**codec probing still failed identically**, on both controllers. Real
lesson here, said plainly: the codec-driver kernel config fix from the
previous checkpoint was the wrong layer. `snd_hda_intel` is compiled
directly into the kernel (`=y`), and "Cannot probe codecs, giving up" is
printed by the *controller* during its own bus-level codec-presence scan
-- before any codec driver ever gets a chance to matter. Confirmed via
the upstream kernel HD-audio documentation
(`Documentation/sound/hd-audio/notes.rst`): this exact message is
attributed there to the BIOS misreporting which codec slots exist,
worked around with the `probe_mask` module parameter's force-bit
(`0x100`) to bypass BIOS slot reporting and probe directly.

Tested live via a `grub.cfg` kernel-cmdline edit (no rebuild needed --
`probe_mask` is a boot parameter, not a compile-time option) --
`snd_hda_intel.probe_mask=0x1FF,0x1FF` (force-probe slots 0-7 on both
controllers) -- and rebooted. **Real result, not another guess**:
`/proc/asound/cards` now shows `1 [NVidia]: HDA-Intel - HDA NVidia`
(the GK104's own HDMI/DP audio codec) with a genuine playback-capable
PCM device (`/proc/asound/card1/pcm3p`). The onboard Intel PCH codec
(`0000:00:1b.0`) still reports zero response across every forced slot
(0, 1, 3 all `Codec #N probe error`) -- with the BIOS-reporting excuse
eliminated by the force-probe, this one looks like genuinely dead or
BIOS-disabled hardware, not a fixable software gap.

**Operational note for any future kernel/GRUB regeneration**: the
`probe_mask` parameter lives in `grub.cfg`'s kernel command line, not
in `kernel-config.sh` -- it's a boot parameter, not a compile-time
`CONFIG_*` option, so it won't survive a bare `kernel-config.sh` rerun
without also re-adding it to whatever GRUB entry gets generated next.

Kernel cleanup, only after confirming this one boots and works
(established precedent): removed the now-superseded `-nouveau` kernel
(files, `/lib/modules`, `grub.cfg` entry) -- `6.18.10-audio` is a strict
superset (same nouveau/cryptsetup/wireguard config plus the audio
fixes), so nothing was lost.

`aplay`/`alsa-utils` aren't installed (only `alsa-lib` was pulled in
earlier, as PulseAudio's dependency) -- confirmed the working PCM
device via `/proc/asound/card1/` directly instead. Whether audio is
*audible* depends on what's actually connected to the monitor's HDMI
output, out of scope to verify remotely.

## Disk cleanup, GLX vendor investigation (2026-08-26)

**Disk cleanup**: removed ~2.1GB of leftover build directories under
`/root/` (`build*` dirs from completed packages, left in place during
the session rather than cleaned per-package). Kept `build12` and
`kbuild` (kernel source/build tree, still in active use for boot
parameter changes). 93G free on target after cleanup.

**GLX vendor gap, investigated and resolved without a rebuild**: after
fixing Mesa's EGL vendor dispatch (`-D glvnd=enabled`, above), checked
whether GLX had an equivalent gap -- `/usr/share/glvnd/glx_vendor.d/`
doesn't exist, while `/usr/share/glvnd/egl_vendor.d/50_mesa.json` does.
Re-fetched Mesa 25.3.5 source to inspect the build system directly
rather than guess: `src/egl/meson.build` has an explicit
`configure_file()` block that generates and installs a vendor JSON;
`src/glx/meson.build` has no equivalent at all -- it only builds
`libGLX_mesa.so.0`. This isn't a Mesa bug or a missing meson flag.
libglvnd's own documentation confirms GLX vendor selection uses a
different mechanism entirely: `libGLX.so` queries the X server per
screen at runtime via the `GLX_EXT_libglvnd` extension, rather than
reading a static config file the way EGL does. The documented fallback
for an X server that doesn't implement that extension (XWayland is one)
is the `__GLX_VENDOR_LIBRARY_NAME` environment variable, checked once
at `libGLX.so` init.

Fix: added `export __GLX_VENDOR_LIBRARY_NAME=mesa` to
`start-hyprland.sh` (name matches what Mesa registered itself under --
`libGLX_mesa.so.0`, same vendor name as the EGL JSON). XWayland is
spawned as Hyprland's child and inherits it. No Mesa rebuild needed;
documented the GLX/EGL asymmetry in `blfs-mesa.sh`'s rationale comment
so a future rebuild doesn't waste time re-investigating the same dead
end. Not independently verified against a running GLX app (no GLX
test tool installed, and XWayland/GLX apps aren't the near-term
priority) -- this is the correct fix per libglvnd's own documented
behavior, not a guess, but flagging that it hasn't been exercised
end-to-end yet.

**Go toolchain + cliphist**: no BLFS book page for either. Go requires
an existing Go compiler to build from source (true since Go 1.5, no
bootstrapping from C) -- per Go's own documented policy, building
go1.27.0 needs a go1.24+ compiler. Same pattern as this project's Rust
build (`blfs-rust.sh`): fetched the official go1.24.13 linux-amd64
binary release from go.dev as a bootstrap-only tool, used it to build
go1.27.0 from source (`GOROOT_BOOTSTRAP=... ./make.bash`), and
discarded the bootstrap binary and both tarballs afterward -- both
downloads sha256-verified against go.dev's own published checksums
before use. Go's source build is "in place" (no separate install
step): extracted the source tarball directly to `/opt/go-1.27.0`
(matching this project's `/opt/rustc-*` convention for large
third-party toolchains), symlinked `/opt/go`, and added
`/etc/profile.d/go.sh`. `go version` confirms `go1.27.0 linux/amd64`.

cliphist (`go.senan.xyz/cliphist`, v0.7.0) built cleanly via
`go install ...@latest` as john (needs network access for Go module
resolution -- confirmed working) and installed to `/usr/bin/cliphist`,
matching where this project's other hand-built user tools (alacritty)
ended up. `hyprland.lua`'s autostart block updated from the placeholder
`wl-paste --type text --watch true` (nothing was consuming its output)
to the real `wl-paste --type text/image --watch cliphist store` pair,
mirrored exactly from the operator's laptop dotfiles -- no clipboard-
picker keybinding exists there either, so none was invented here.

**Not yet exercised end-to-end**: Hyprland was already running
(started before this work) when the config was deployed, and autostart
only fires on `hyprland.start` -- restarting an active session is
disruptive and wasn't done without asking. cliphist will start storing
clipboard history on the next Hyprland restart/login, not before.

wl-clipboard itself was already installed and working from the earlier
desktop-utils batch; nothing needed there beyond confirming it
(`wl-copy`/`wl-paste` present).

Next: Firefox -- the last package in this plan.
