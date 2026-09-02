---
name: lfs-audit
description: Full health/security/hardware-utilization audit of one LFS/BLFS host in this repo -- cleanup candidates, service/log errors, suspicious processes, security posture, unbound hardware, packages not exploiting hardware features, and binary/doc size hygiene. Read-only by default; codifies the ad-hoc checks run by hand during server's first build so they don't have to be re-typed every time.
---

# lfs-audit

**Invocation:** `/lfs-audit [host]` -- host defaults to the resolved host (`--host`,
else `$LFS_HOST`, else the hostname), same resolution order as every `bin/` tool.

**Scope:** This audits a **live, native** system -- a host that has booted into its own
LFS tree and is running for real (`server` today; `laptop` once deployed). Most sections
are meaningless against an offline chroot tree (no running services, no live processes,
no bound hardware) -- if the resolved host is still chroot-only, say so up front and skip
straight to the sections that *do* apply to an offline tree (B's log-file checks against
`hosts/<h>/logs/`, D's manifest/permission checks, G, H).

**Read-only by default.** Every section reports findings; none of them delete, strip,
compress, or reconfigure anything without you reviewing the list and saying to proceed.
Where a fix is genuinely safe and mechanical (stripped binaries, gzipped man pages), say
so plainly in the report and offer to do it, but don't do it inline as part of the scan.

## Why this exists

Every check below was run by hand, ad hoc, at some point during `server`'s first build
and rebuild history -- ther's no reason to re-derive the same command each time. Several
sections cite the specific incident that proved the check mattered, from
`hosts/server/BUILD-REPORT.md`, `PRACTICES.md`, and this session's own `laptop` build:
the cpufreq governor pinned at 1600MHz (2.1x measured loss), the misreported HDA codec
slots needing a boot parameter, the `xorg-server`/`xwayland` manifest overlap on
`/usr/bin/Xvfb`, and laptop's own still-open `Vulnerability Old microcode: Vulnerable`
finding from its hardware audit. The point of writing this down is the same as the
point of `review-overrides.json`: a decision or a check, once made, shouldn't have to be
rediscovered by the next session.

## Procedure

1. Resolve the host: `python3 bin/lfshost.py --host <host>` (or no flag, on the machine
   itself). Note whether it's native or chroot-only before running anything else.
2. Work through sections A-J below in order, running the commands shown. Skip a command
   cleanly (note it, don't error) if the tool it needs isn't installed on this host --
   this project has no package manager, so "not built yet" is a normal, expected state,
   not a bug in the audit.
3. Compile one report, grouped by section, each finding tagged with a rough severity
   (`critical` / `worth doing` / `fyi`). Don't bury a real finding in a wall of `fyi`
   noise -- lead with anything `critical`.
4. For anything actionable, name the exact fix command but do not run it unless asked.
   Cross-reference `hosts/<h>/review-overrides.json` / `blfs-overrides.json` conventions
   for anything that would become a standing decision (e.g. a kernel config change) --
   that belongs recorded there, not just fixed once and forgotten.

## A. Disk cleanup & reclaimable space

Why: this project has repeatedly run builds within single-digit GB of free space
(`laptop`'s whole chroot-in-repo build, `server`'s outage-recovery section) -- knowing
what's reclaimable *before* it's an emergency is cheap; finding out during a build that
just OOM'd on disk is not.

```sh
df -h                                          # overall headroom, every mount
du -sh /var/tmp /tmp 2>/dev/null                # scratch dirs
find /var/tmp /tmp -mtime +7 -type f 2>/dev/null | head -50   # stale scratch files
journalctl --disk-usage                        # journal size
find /var/lib/systemd/coredump -type f 2>/dev/null    # core dumps, if enabled
find /boot -maxdepth 1 -name 'vmlinuz-*' -o -name 'System.map-*' -o -name 'config-*' \
  | sort                                        # old kernels; cross-check against grub.cfg
grep -o "vmlinuz-[^ ]*" /boot/grub/grub.cfg 2>/dev/null | sort -u   # kernels grub.cfg actually boots
du -sh ~/.cargo/registry ~/.cargo/git 2>/dev/null   # rust build caches, can be multi-GB
du -sh ~/.npm ~/.cache/pip 2>/dev/null              # node/python build caches
find / -xdev -name '*.orig' -o -name '*.rej' -o -name '*~' 2>/dev/null | grep -v /proc
```

Also run, if a package database exists (`hosts/<h>/manifests/` populated):
```sh
bin/lfsmaint --root / orphans     # files on disk owned by no package -- see section H
```

Flag: any `/boot` kernel/initrd not referenced by the active `grub.cfg` (safe to remove
once confirmed unreferenced); `~/.cargo`/`~/.npm` caches larger than a few hundred MB if
no more Rust/Node builds are imminent; core dumps older than the incident that made them.

## B. Service & log errors

```sh
systemctl --failed                              # units that failed to start
systemctl list-units --state=error,failed
journalctl -p err..alert -b                     # this boot, error priority and worse
journalctl -p warning -b --no-pager | tail -100  # warnings, last 100 (noisy, skim don't dump)
dmesg --level=err,warn 2>/dev/null | tail -60    # kernel ring buffer
journalctl -u <unit> --since "-7d" -p warning    # per-unit, for anything flagged above
```

Cross-check against this project's own known-good unit set
(`overlay/units/`, `hosts/<h>/overlay/`): `lfsmaint-check.timer`,
`cpufreq-governor.service`, `sshd.service`, `iptables.service`, `update-pki.timer` --
confirm each is `enabled` and `active`, not just installed:
```sh
systemctl is-enabled lfsmaint-check.timer cpufreq-governor.service sshd.service \
  iptables.service update-pki.timer 2>&1
```

Flag: any `failed` unit; repeated warnings from the same unit (a flapping service);
a known-good unit from the list above that's installed but not enabled.

## C. Suspicious processes

```sh
ps -eo pid,ppid,user,stat,etime,cmd --sort=-etime | head -40   # longest-running, skim for surprises
ps -eo pid,cmd | sort -k2 | uniq -f1 -D              # exact duplicate command lines (candidate: stuck/re-spawned)
ps -eo pid,stat,cmd | awk '$2 ~ /Z/'                 # zombies
for p in /proc/[0-9]*; do
  [ -L "$p/exe" ] && readlink "$p/exe" | grep -q '(deleted)$' && echo "$p: $(readlink "$p/exe")"
done                                                   # running a binary since-replaced on disk -- needs a restart
ss -tlnp 2>/dev/null                                  # listening TCP, with owning process
ss -ulnp 2>/dev/null                                  # listening UDP
ps -eo pid,ppid,cmd | awk '$2==1' | grep -v -E 'systemd|kthread|^\s*PID'   # reparented-to-init, unexpected for non-daemons
```

This is the exact class of bug that already happened once in this project (`bin/lfsbuild`
run twice concurrently, a stale `/tmp/_lfsstep.sh` from an earlier non-sudo dry run,
2026-08-27) -- a duplicate-command-line or deleted-exe finding here is worth chasing down,
not dismissing.

Flag: any zombie with a live parent that should be reaping it; any duplicate long-running
command line for something meant to be a singleton (a build driver, a daemon); any
`(deleted)` executable still running (means a binary was updated/removed without the
process restarting -- often security-relevant, e.g. a patched library not yet in effect).

## D. Security posture

```sh
find / -xdev -perm -4000 -o -perm -2000 2>/dev/null | sort    # SUID/SGID inventory
find / -xdev -perm -0002 -type f 2>/dev/null                  # world-writable files
find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null    # world-writable dirs, no sticky bit
find /etc/ssh /root/.ssh /home/*/.ssh /root/.gnupg -type f \
  \( -perm -044 -o -perm -004 \) 2>/dev/null                  # world/group-readable key material
awk -F: '($2==""){print $1" has an empty password field"}' /etc/shadow 2>/dev/null   # needs root
awk -F: '($3==0 && $1!="root"){print $1" has UID 0"}' /etc/passwd
iptables -L -n -v 2>/dev/null                                  # active firewall rules, if built
ss -tlnp 2>/dev/null                                            # cross-check open ports against the above
```

Then delegate to the project's own tracker rather than re-deriving it:
```sh
bin/lfsmaint --root / advisories     # LFS/BLFS security advisories affecting installed packages
```

Every SUID/SGID binary should be traceable to a package (`bin/lfsmaint owns <path>`) --
one that isn't is worth a specific look. Compare the world-writable/SUID list against the
last audit's list if one exists (see "Output format" below) so a *new* SUID binary or a
newly-world-writable file stands out instead of scrolling past in a wall of expected
entries (`/usr/bin/passwd`, `/usr/bin/sudo`, etc. are expected).

Flag: any SUID/SGID binary not owned by a known package; any world-writable file outside
`/tmp`/`/var/tmp`; any private key with group/other read permission; any non-root UID 0
account; any advisory at Critical/High severity for an installed package.

## E. Hardware without a bound kernel driver

Why: this is precisely the class of thing this project has already measured real cost
from -- the GTX 770 sitting with zero driver bound until `CONFIG_DRM_NOUVEAU` was added
(server), and the HDA codec slots the BIOS misreported until a boot parameter force-probed
them (server). A device with no driver bound is either genuinely unsupported (fine, but
worth knowing) or missing one kernel-config line away from working.

```sh
lspci -k                          # every PCI device + "Kernel driver in use" line
lspci -k | grep -B3 -i "kernel driver in use" | grep -B3 "^$" # (or just skim for entries with no "Kernel driver in use" line at all)
lsusb -v 2>/dev/null | grep -E "^Bus|Driver=" | grep -B1 "Driver=$"   # USB devices, no driver claimed
ls /sys/class/net/ 2>/dev/null                        # network interfaces actually present
```

For any PCI/USB device with no bound driver: get its vendor:device ID (`lspci -n` /
`lsusb`), check it against `hosts/<h>/host.toml`'s `[hardware]` table (already-documented
facts) and `hosts/<h>/kernel-config.sh` (already-added config) -- if it's genuinely new
or was never resolved, that's a `kernel-config.sh` gap, recorded the way every other
hardware decision in this project is: a comment citing what was tried and measured.

Flag: any PCI device with no kernel driver in use, unless already documented as
intentionally unsupported; any USB device (especially input/audio/storage) with no
driver claimed.

## F. Hardware-feature utilization

Why: this is the category the project's own README calls out as its best-performing --
"the small tweaks that are hard to find... that nobody would chase down by hand." Also
the most host-specific: what "underused" means depends entirely on this machine's actual
silicon, so cite `host.toml`'s `[hardware]` table rather than assuming.

**CPU:**
```sh
cat /proc/cpuinfo | grep -m1 flags | tr ' ' '\n' | grep -E '^(avx|sse4|aes|bmi)' # what the CPU actually offers
grep -m1 bugs: /proc/cpuinfo                     # old_microcode / other unmitigated bugs
cat /proc/cpuinfo | grep -m1 "microcode"
cpupower frequency-info 2>/dev/null || cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```
This project builds every package at GCC's generic x86-64 baseline (no `-march=native`
anywhere in a recipe or override, confirmed by inspection) -- that's a deliberate
portability choice for a *shared* recipe tree serving more than one CPU, not a bug, but
worth stating explicitly in the report so it isn't mistaken for an oversight. The
governor check is not cosmetic: server measured a 2.1x real-workload loss from
`CPU_FREQ_DEFAULT_GOV_USERSPACE` defaulting on with nothing driving it -- confirm the
running governor matches what `kernel-config-base.sh`'s gate asserts (`schedutil`).
`grep -m1 bugs:` catching `old_microcode` means an early-load microcode initrd is needed
and not yet built -- laptop's own hardware audit already found this and it is still open.

**GPU:**
```sh
lspci -k | grep -A3 VGA                           # driver bound
ls /usr/lib/dri/ 2>/dev/null                      # mesa drivers actually installed
find /usr/share/vulkan/icd.d -name '*.json' -exec cat {} \; 2>/dev/null   # Vulkan ICD(s) registered
glxinfo -B 2>/dev/null || eglinfo 2>/dev/null      # renderer string, if mesa-demos/wayland-utils built
cat /sys/class/drm/*/device/uevent 2>/dev/null | grep DRIVER=
```
Compare against `host.toml`'s `[hardware].gpu` line and whatever `blfs-overrides.json`
recorded for `gallium-drivers=`/`vulkan-drivers=` -- confirm the driver actually bound at
runtime matches what mesa was built for, not a fallback (llvmpipe/swrast) silently taking
over because the real one failed to load.

**Video accel / media:**
```sh
ffmpeg -hwaccels 2>/dev/null
ffmpeg -decoders 2>/dev/null | grep -i vaapi
mpv --hwdec=help 2>/dev/null
grep -i hwdec ~/.config/mpv/mpv.conf /etc/mpv/mpv.conf 2>/dev/null
vainfo 2>/dev/null   # if libva-utils built -- confirms VAAPI actually reaches the GPU, not just linked
```

**Storage:**
```sh
cat /sys/block/*/queue/scheduler 2>/dev/null      # none/mq-deadline expected for NVMe/SSD; bfq/cfq is a spinning-disk default that leaked through
cat /sys/block/*/queue/rotational 2>/dev/null     # cross-check: 0 = SSD/NVMe, should pair with the scheduler above
```

Flag: `old_microcode` (or any unmitigated bug) in `/proc/cpuinfo` with no matching
`intel-microcode`/`amd-microcode` recipe built for this host; cpufreq governor not
`schedutil`/`performance`; GPU renderer falling back to software (llvmpipe/swrast) when a
hardware driver was built; VAAPI/hwaccel linked into ffmpeg/mpv per `ldd` but not actually
reachable per `vainfo`; an NVMe/SSD using a rotational-disk I/O scheduler.

## G. Binary/doc size hygiene (strip + compress)

Why: explicitly requested, and genuinely cheap -- a from-scratch build has no
distro-level "strip debug info at packaging time" step the way a binary distro does, so
this project's own installed tree accumulates full debug sections and uncompressed man
pages by default unless a recipe specifically stripped them.

```sh
find /usr/bin /usr/sbin /usr/lib -type f -exec sh -c \
  'file "$1" | grep -q "not stripped" && echo "$1"' _ {} \; 2>/dev/null | head -50
# total reclaimable, roughly:
find /usr/bin /usr/sbin /usr/lib -type f -exec file {} \; 2>/dev/null \
  | grep "not stripped" | wc -l
find /usr/share/man -name '*.[1-9]' ! -name '*.gz' 2>/dev/null | head -20   # uncompressed man pages
find /usr/share/info -name '*.info*' ! -name '*.gz' 2>/dev/null | head -20 # uncompressed info pages
du -sh /usr/lib/debug 2>/dev/null                                          # separate debug-info tree, if any
```

The actual fix, offered but not auto-run:
```sh
find /usr/bin /usr/sbin /usr/lib -type f -exec sh -c \
  'file "$1" | grep -q "not stripped" && strip --strip-debug "$1"' _ {} \; 2>/dev/null
find /usr/share/man -name '*.[1-9]' ! -name '*.gz' -exec gzip -9 {} \;
find /usr/share/info -name '*.info*' ! -name '*.gz' -exec gzip -9 {} \;
```
`--strip-debug`, not `--strip-unneeded` or `--strip-all`: this project already recorded
why (`libc.a` stripped with `--strip-unneeded` breaks statically-linked Rust programs
with SIGSEGV on startup, a real Glibc-2.42+ bug -- LFS's own book switched to
`--strip-debug` for exactly this reason, and this skill follows the same rule). Don't
strip anything already stripped (wastes time, risk-free but pointless) and don't touch
`/usr/lib/debug` if it exists on purpose (a deliberately-kept separate debug-info tree,
not a mistake).

Flag: report the count and rough disk-space estimate; only actually strip/compress on
request.

## H. Package-manifest integrity

Delegate entirely to the existing tool rather than re-deriving any of this by hand:
```sh
bin/lfsmaint --root / report      # one-page summary: packages, files, biggest, slowest builds
bin/lfsmaint --root / verify      # manifested files now missing (excludes known-pruned classes)
bin/lfsmaint --root / orphans     # files present, owned by no package
```
`report`'s own database build (`lfsmaint db`) already flags files claimed by more than
one package -- the exact bug class that bit `server` for real (`xorg-server` and
`xwayland` both installing `/usr/bin/Xvfb`; a stale `lua5.4` manifest after `lua5.5`
silently clobbered its generic, unversioned install paths). Re-run `lfsmaint db` first if
it hasn't been rebuilt since the last package install.

Flag: any `verify` result outside the already-known-pruned classes; any `orphans` entry
under `/etc` (config drift matters more there than under `/usr`); any multi-owner file
conflict `db` reports.

## I. Boot & unit-file hygiene

```sh
systemd-analyze                                    # total boot time
systemd-analyze blame | head -20                   # slowest units to start
systemd-analyze critical-chain                      # the actual critical path
systemctl list-unit-files --state=enabled | wc -l   # sanity count -- compare to last audit
diff <(systemctl list-unit-files --state=enabled) /tmp/last-enabled-units.txt 2>/dev/null
systemctl list-timers --all                          # every timer, active or not
```

Flag: any single unit taking a disproportionate share of boot time with no known reason;
a timer that's `enabled` but shows no recent/next trigger (misconfigured OnCalendar); an
enabled-unit-count that jumped since the last audit with nothing intentional installed to
explain it (possible sign of something enabling itself unexpectedly).

## J. Filesystem & mount sanity

```sh
findmnt --verify                                    # fstab vs actual state, systemd's own checker
cat /etc/fstab
mount | grep -v -E '^(proc|sysfs|devpts|tmpfs|devtmpfs|cgroup2) '   # real block-device mounts
lsblk -f                                            # actual labels/UUIDs on disk
```
This project's own `ch10-fstab` convention mounts by `LABEL=`, specifically so the tree
isn't bound to a device node that can shift -- confirm the labels `blkid`/`lsblk` actually
see on disk still match what `/etc/fstab` (and, for the *next* rebuild, `review-
overrides.json`'s `ch10-fstab` block) expects. A label mismatch here is "unbootable after
the next reformat," not a cosmetic issue.

Flag: `findmnt --verify` reporting any real problem (not just informational notes); an
`/etc/fstab` entry whose `LABEL=`/`UUID=` doesn't match anything `lsblk -f` currently
shows.

## Output format

One report, sections A-J in order, each either "clean" (one line) or a bulleted finding
list tagged `critical` / `worth doing` / `fyi`. End with a short "since last audit" note
if a prior report exists to diff against (save this run's raw findings to
`hosts/<h>/state/audit-<date>.md` so the next invocation has something to compare to --
this is the one piece of state this skill keeps; everything else is read fresh every
time). Lead with anything `critical` across all sections, not buried in its own section.

## Does not do

- Does not delete, strip, compress, restart a service, or change any config as part of
  running the audit -- report first, act only on explicit request, one section at a time.
- Does not guess at what a genuinely ambiguous finding means (an unrecognized SUID
  binary, an unbound PCI device with no obvious driver) -- reports it plainly and says
  it needs a human decision, the same way `review-overrides.json` refuses to guess a
  book decision.
- Does not replace `bin/lfsmaint`'s own advisory/drift/db commands -- calls them, doesn't
  reimplement them.
- Does not run destructive `find -delete` or similar on its own initiative anywhere in
  this document -- every listing command is inspect-only; deletion commands, where
  shown, are explicitly marked as "offered, not auto-run."
