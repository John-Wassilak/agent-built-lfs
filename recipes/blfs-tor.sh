#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for tor (BLFS 13.0-systemd carries no
# Tor page; checked the whole tree, the only hits for "tor" are unrelated words).
# source: dist.torproject.org/tor-0.4.9.11.tar.gz (2026-06-25), the newest stable
# release on the 0.4.9.x series and a security release: ReleaseNotes calls out an
# onion-service rendezvous-point impersonation race (bug 41297), a client assert on a
# malformed introduction-point key (41295) and a conflux fix, and says "We strongly
# recommend upgrading as soon as possible". 0.4.8.25 (the older LTS line) is also
# still published; this host has no reason to stay on it.
#
# provenance: sha256 2e6c1720118c812acf0079fd47cf91b6bfaba5d766c321c4d3d2a28d6a11a8ed
# matches upstream's own published tor-0.4.9.11.tar.gz.sha256sum, and that sha256sum
# file's detached signature verifies GOOD against Alexander Faeroy's key
# 1C1BC007A9F607AA8152C040BEA7B180B1491921 (signing subkey 514102454D0A87DB0767A1EB
# BE6A0531C18A9179), fetched over WKD from torproject.org itself rather than from a
# keyserver. The file carries a second signature from David Goulet's key
# B74417EDDF22AC9F9E90F49142E86A2A11F48D36, which also verifies GOOD but whose key
# expired 2026-03-24 -- recorded because it is real, not relied on. This is a stronger
# record than most non-book tarballs here get (an unsigned upstream sha256, or this
# project's own sha256 of what it downloaded).
#
# rationale: operator-requested (2026-09-07) -- "install and enable tor". Client
# configuration: a local SOCKS proxy on 127.0.0.1:9050 and nothing else. No ORPort, no
# relay, no bridge, no onion service, no exit policy -- adding any of those turns this
# machine into public Tor infrastructure and is an operator decision, not a default.
# `ClientOnly 1` in the torrc below states that rather than leaving it implied by the
# absence of an ORPort.
#
# Portable: nothing here names this host's GPU, disks, kernel or network. Shared
# recipe per CLAUDE.md's shared/host test.
#
# Build notes, each checked against this tarball rather than assumed:
#
#   --enable-systemd    tor's sd_notify support, via libsystemd (259 here). Required
#                       for the Type=notify unit below: without it the unit would have
#                       to be Type=simple and systemd would call the service "started"
#                       the moment the process forked, long before tor has a working
#                       circuit. configure defaults this to `auto`; pinned explicitly
#                       so a missing libsystemd fails the build instead of silently
#                       producing a binary the unit cannot talk to.
#   --enable-lzma       liblzma 5.8.3 (LFS xz) -- directory-document decompression.
#   --enable-zstd       libzstd 1.5.7 (LFS zstd) -- same. Both are off by default and
#                       both are what relays actually serve consensus diffs with, so
#                       leaving them off means falling back to zlib for everything.
#   --disable-seccomp   libseccomp is not in this build's closure, so configure would
#                       skip it anyway; passing it explicitly records the consequence:
#                       torrc's `Sandbox 1` is unavailable on this system. The systemd
#                       unit's own sandboxing below covers the same ground from
#                       outside the process.
#   --disable-html-manual
#                       no asciidoc here. The man pages still install: this release
#                       tarball ships pre-built doc/man/*.1.in (upstream ships them
#                       "so that people without asciidoc can just use the .1 and .html
#                       files" -- doc/include.am), and config.status substitutes
#                       @CONFDIR@/@LOCALSTATEDIR@ into them with no asciidoc involved.
#                       Do NOT pass --disable-asciidoc: that sets USE_ASCIIDOC=false,
#                       which empties nodist_man1_MANS and installs no man pages at
#                       all. The HTML copy of the same manual is what is dropped here.
#
# `--with-tor-user`/`--with-tor-group` are deliberately not passed: in this tarball
# TORUSER/TORGROUP are AC_SUBST-only and nothing but Makefile.in consumes them, so
# they would document an intent the build never acts on. The tor account is created
# below and named in the unit and the torrc, where it is load-bearing.
set -e

TOR_VERSION=0.4.9.11

# The tor daemon's own unprivileged account. `-r` (system range, SYS_UID_MIN..
# SYS_UID_MAX from login.defs -- above 100) rather than a fixed low id: LFS and BLFS
# hand out 0-99 by name in their own pages (sshd 50, polkitd 27, ldap 83, ntp 87 ...),
# tor is in neither book, and picking a free number out of that range would collide
# the day a book edition assigns it. Same reasoning, and same `-r`, as this project's
# blfs-seatd.sh. getent-guarded so a rebuild does not fail on the second run.
getent group  tor > /dev/null || groupadd -r tor
getent passwd tor > /dev/null || useradd -r -g tor -d /var/lib/tor -s /bin/false \
    -c "Tor Daemon Owner" tor

# Guard against make regenerating the shipped man page sources. The rule
# `doc/man/tor.1.in: doc/man/tor.1.txt` fires asciidoc-helper.sh if the .txt is newer
# than the .in, and every file in this tarball carries the same mtime (1782410294), so
# the two are currently equal and make treats the target as up to date. That is one
# `touch` away from being wrong, and the failure would be a hard error (no a2x on this
# system) at the very end of a long build. Make it explicit instead of lucky.
touch doc/man/*.1.in doc/man/*.html.in

./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --docdir=/usr/share/doc/tor-$TOR_VERSION \
            --enable-systemd                     \
            --enable-lzma                        \
            --enable-zstd                        \
            --disable-seccomp                    \
            --disable-html-manual

make

# tor's own unit tests. Kept in the recipe rather than run once by hand: this is a
# network daemon handling hostile input, and its test suite is self-contained (no
# network, no relay, no live consensus).
make check

make install

# DataDirectory. systemd's StateDirectory=tor in the unit would create this too, but
# creating it here means the permissions are right before the first start rather than
# on it, and 0700 is not optional -- tor refuses to run if its DataDirectory is group-
# or world-readable, and the directory holds the client's entry-guard choices.
install -v -d -o tor -g tor -m 0700 /var/lib/tor

# torrc. `make install` ships /etc/tor/torrc.sample (upstream's annotated template,
# left in place as reference); this is the file tor actually reads. Written only when
# absent so a rebuild or a version bump never overwrites operator edits -- the same
# reason BLFS's own config steps guard their /etc writes.
install -v -d /etc/tor
if [ ! -f /etc/tor/torrc ]; then
    cat > /etc/tor/torrc << "ENDOFTORRC"
# /etc/tor/torrc -- Tor client configuration.
#
# Client only: a SOCKS proxy for this machine's own applications. This host is not a
# relay, a bridge, an exit or an onion service; each of those is a deliberate decision
# with real consequences for the network and for this machine, so none is on by
# default. See tor(1) and /etc/tor/torrc.sample.

# Refuse to act as a relay even if a future edit adds an ORPort by accident.
ClientOnly 1

# The SOCKS5 proxy. Loopback only -- the default, restated because the consequence of
# widening it is that anyone who can reach the port can see what this machine browses
# (tor(1): "Untrusted users who can access your SOCKSPort may be able to learn about
# the connections you make").
SocksPort 127.0.0.1:9050

# Owned by the tor account created by this package's recipe, mode 0700.
DataDirectory /var/lib/tor

# Log to stdout, which under the systemd unit means the journal
# (`journalctl -u tor`). 'notice' is upstream's recommendation: anything more verbose
# records what this machine did with its circuits.
Log notice stdout
ENDOFTORRC
    chmod 644 /etc/tor/torrc
fi

# systemd unit. Written here rather than taken from the tarball because this release
# ships none -- upstream's contrib/ has client-tools, operator-tools and or-tools and
# no dist/ directory, so there is no tor.service.in to install (unlike blfs-tailscale,
# which installs upstream's own unit file).
#
# Type=notify is what --enable-systemd above buys: tor calls sd_notify(READY=1) only
# once it has bootstrapped, so `systemctl start tor` returning success means the SOCKS
# port is actually usable, and anything ordered After=tor.service gets a working proxy
# rather than a process that has just started opening sockets.
#
# The Protect*/Restrict*/CapabilityBoundingSet block is the reason --disable-seccomp
# above is acceptable: tor's in-process `Sandbox 1` is unavailable without libseccomp,
# so the confinement is applied from outside by systemd instead. tor as a pure client
# needs read-only /etc, its own state directory, and outbound TCP -- nothing else.
install -v -d /usr/lib/systemd/system
cat > /usr/lib/systemd/system/tor.service << "ENDOFUNIT"
[Unit]
Description=Anonymizing overlay network for TCP
Documentation=man:tor(1) https://www.torproject.org/docs/
After=network.target nss-lookup.target

[Service]
Type=notify
NotifyAccess=main
User=tor
Group=tor
ExecStartPre=/usr/bin/tor -f /etc/tor/torrc --verify-config
ExecStart=/usr/bin/tor -f /etc/tor/torrc
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
# Bootstrapping a first consensus on a slow or filtered network takes minutes, and
# systemd's 90s default would kill it mid-handshake and call the service failed.
TimeoutStartSec=300
Restart=on-failure
RestartSec=5
LimitNOFILE=32768

RuntimeDirectory=tor
RuntimeDirectoryMode=0700
StateDirectory=tor
StateDirectoryMode=0700

# Sandbox. A Tor client needs no capabilities at all: its only listener is a high
# loopback port and it never touches hardware, other users' files or kernel state.
CapabilityBoundingSet=
AmbientCapabilities=
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=strict
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
ProtectClock=yes
ProtectProc=invisible
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
ENDOFUNIT
chmod 644 /usr/lib/systemd/system/tor.service

systemctl daemon-reload

# Enable and start. This project's other live-system services do the same from their
# own recipe (blfs-networkmanager.sh, blfs-seatd.sh, blfs-bluez.sh) -- on a booted
# native host `systemctl enable` runs for real, and the WantedBy symlink is part of
# what this step installs.
systemctl enable tor
systemctl restart tor

echo "### version"
/usr/bin/tor --version
