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
| Deliverable | `lfs-13.0-systemd-claude-20260825.tar.gz` — 820 MB, 75,674 entries |
| SHA256 | `e69836ca656a40969502685fa7e612c6c770e981614e30d47b68b735863b4cf6` |
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
