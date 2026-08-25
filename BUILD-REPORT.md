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
