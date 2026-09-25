#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page for nginx (BLFS 13.0-systemd carries no
# nginx page; `find book/blfs-13.0 -iname '*nginx*'` and a case-insensitive grep of the
# whole book tree both return nothing -- the book's only HTTP servers are Apache and
# lighttpd). Re-checked against book/blfs-13.1 on 2026-09-24: still none.
#
# The recipe is version-neutral; the tarball comes from each host's packages.py entry.
# laptop (seq 320) built 1.30.4, server (seq 264) built 1.30.5.
#
# source : nginx.org/download/nginx-1.30.5.tar.gz -- upstream's own canonical download
# host. 1.30.5 is the head of the *stable* branch (nginx numbers even minors stable, odd
# minors mainline; 1.31.6 is the current mainline). Stable is the right branch for a
# machine that serves files and is not tracking new features.
#
# provenance, 1.30.5: sha256
# 6c20565aa2325cb82216ae804f4a4ff1875179014759a381c42ddc8e11c4906d; the detached
# signature verifies GOOD against Sergey Kandaurov's key
# D6786CE303D9A9022998DC6CC8464D549AF75C0A (uid s.kandaurov@f5.com), signature made
# 2026-09-15, key from nginx.org/keys/pluknet.key -- same-origin, as below.
#
# provenance, 1.30.4: sha256 4261dc90e9e47c1c4041276e9aaa3d48ebe2e664f728e14fa95ae6c67d57a08b,
# and the detached signature nginx-1.30.4.tar.gz.asc verifies GOOD against Roman
# Arutyunyan's key 43387825DDB1BB97EC36BA5D007C8D7C15D87369 (RSA, uid
# r.arutyunyan@f5.com / arut@nginx.com), signature made 2026-07-15. That key was taken
# from nginx.org/keys/arut.key, i.e. the same TLS origin as the tarball -- so this is a
# same-origin integrity check, not the independent trust path that tor's WKD-fetched key
# gives blfs-tor.sh. Recorded as what it is. arut.key is one of the four release-manager
# keys nginx.org/en/pgp_keys.html lists.
#
# version selection is a security decision here, not a preference. Checked against
# nginx.org/en/security_advisories.html on 2026-09-08: the three newest advisories --
# CVE-2026-42533 (major, buffer overflow with `map` plus a regex), CVE-2026-60005
# (medium, memory disclosure in ngx_http_slice_module) and CVE-2026-56434 (medium,
# use-after-free in ngx_http_ssi_module) -- all read "Not vulnerable: 1.31.3+, 1.30.4+".
# 1.30.4 is therefore the oldest stable release that clears every published advisory.
# Anything on 1.28.x or 1.26.x is vulnerable to all three.
#
# Re-checked 2026-09-24: CVE-2026-90439 (medium, buffer overflow in
# ngx_http_v3_module) reads "Not vulnerable: 1.31.6+, 1.30.5+; Vulnerable:
# 1.29.2-1.31.5". This recipe never passes --with-http_v3_module (HTTP/3 is not a
# default module), so a 1.30.4 build from it does not contain the vulnerable code --
# but 1.30.5 is the release that clears every advisory, and new builds should use it.
# 1.30.5's CHANGES lists that fix and one QUIC-only change, nothing else.
#
# rationale: operator-requested (2026-09-08) -- "install nginx". Serves a local file
# tree over HTTP. The docroot, the listen address and the vhosts are all host decisions
# and are NOT in this file; see the config note below.
#
# Portable: this recipe names no device, no filesystem label, no GPU and no docroot.
# The default /etc/nginx/nginx.conf it writes is deliberately a stub that serves nothing
# but a placeholder page on loopback -- see the block that writes it. Shared recipe per
# CLAUDE.md's shared/host test; a machine's real nginx.conf belongs in its overlay
# (hosts/<h>/overlay/etc/nginx/nginx.conf), which is where `laptop`'s lives.
#
# Dependencies, all already in this build's closure and all checked on the live system
# before this step was written rather than assumed:
#   pcre2 10.47   LFS chapter 8. Required for the rewrite and location-regex support
#                 nginx builds by default. `pcre2test -C` reports "Just-in-time
#                 compiler support / Can allocate executable memory: Yes", which is what
#                 makes --with-pcre-jit below legal rather than a configure failure.
#   openssl 3.6.1 LFS chapter 8. Required by --with-http_ssl_module.
#   zlib 1.3.2    LFS chapter 8. Required by the gzip filter, which is a default module.
#
# Build notes, each checked against `./configure --help` in this tarball:
#
#   path flags        nginx's --prefix is both its install root and the base every other
#                     default path hangs off, so a bare --prefix=/usr would put the
#                     config in /usr/conf and the logs in /usr/logs. Every path is
#                     therefore given explicitly. The layout is the conventional one:
#                     binary in /usr/sbin, config in /etc/nginx, pid in /run, logs in
#                     /var/log/nginx, scratch in /var/lib/nginx.
#   --user/--group    compiles the nginx account in as the worker identity, so a config
#                     that omits the `user` directive still drops privileges. The master
#                     process stays root because binding a port below 1024 requires it.
#   --with-threads    thread pools, and
#   --with-file-aio   AIO, both off by default. Together they let `aio threads;` in a
#                     config move blocking disk reads off the worker's event loop, which
#                     is the difference between one large file and one *concurrent*
#                     large file on a spinning-platter-era read path. Enabled here
#                     because they cost nothing when a config does not use them.
#   --with-pcre-jit   PCRE2's JIT for compiled regexes. Legal on this system -- see the
#                     pcre2test check above.
#   --with-http_ssl_module
#                     TLS. Not a default module. Enabled unconditionally: a build without
#                     it cannot be given a certificate later without a full rebuild, and
#                     openssl is already a hard dependency of the rest of this system.
#   --with-http_v2_module
#                     HTTP/2, which needs the ssl module. Also not default.
#   --with-http_realip_module
#                     lets a config trust X-Forwarded-For from a known proxy. Not
#                     default; needed the day this sits behind anything.
#   --with-http_gzip_static_module
#                     serves a pre-compressed foo.gz instead of compressing on every
#                     request. Not default.
#   --with-http_stub_status_module
#                     the /nginx_status counters. Not default. Nothing here exposes it;
#                     it is compiled so that diagnosing a stuck worker later does not
#                     mean rebuilding the server first.
#   --without-http_ssi_module
#                     server-side includes, which ARE a default module. Turned off: no
#                     config in this repo uses SSI, and it is the module behind
#                     CVE-2026-56434 (use-after-free), one of the three advisories that
#                     forced 1.30.4 above. An unused parser removed is one fewer thing
#                     the next advisory can be about.
#
# Two dangerous modules need no flag at all because nginx does not build them by
# default, and this recipe deliberately does not ask for them:
#   ngx_http_mp4_module   (--with-http_mp4_module) MP4 pseudo-streaming. It is the single
#                         most advisory-prone module in nginx's history -- CVE-2026-27784,
#                         CVE-2026-32647, CVE-2024-7347 and CVE-2022-41741 are all it --
#                         and it is not needed to serve .mp4 files. Ordinary static
#                         serving plus HTTP range requests is what an HTML5 <video> tag
#                         uses to seek; the mp4 module only adds ?start= offset rewriting.
#   ngx_http_dav_module   (--with-http_dav_module) WebDAV, i.e. PUT and DELETE over HTTP.
#                         CVE-2026-27654. Nothing here needs write access.
#
# There is no `make check`: nginx ships no test suite in the release tarball. Its tests
# live in a separate nginx-tests repository and need Perl's Test::Nginx, which is not in
# this build's closure. The recipe verifies the binary by other means at the end --
# `nginx -V`, a config syntax test, and a real HTTP request against the running server.
set -e

NGINX_VERSION=1.30.5

# The worker account. `-r` (system range, SYS_UID_MIN..SYS_UID_MAX -- 101..999 in this
# system's login.defs) rather than a fixed low id, for the same reason as blfs-tor.sh and
# blfs-seatd.sh: LFS and BLFS hand out 0-99 by name in their own pages, nginx is in
# neither book, and picking a free number out of that range collides the day a book
# edition assigns it. getent-guarded so a rebuild does not fail on the second run.
#
# The account is deliberately unable to log in: no valid shell, and its home is the
# scratch directory rather than anything with content in it.
getent group  nginx > /dev/null || groupadd -r nginx
getent passwd nginx > /dev/null || useradd -r -g nginx -d /var/lib/nginx -s /bin/false \
    -c "nginx Web Server" nginx

./configure --prefix=/usr                                        \
            --sbin-path=/usr/sbin/nginx                          \
            --modules-path=/usr/lib/nginx/modules                 \
            --conf-path=/etc/nginx/nginx.conf                    \
            --pid-path=/run/nginx.pid                            \
            --lock-path=/run/lock/nginx.lock                     \
            --error-log-path=/var/log/nginx/error.log            \
            --http-log-path=/var/log/nginx/access.log            \
            --http-client-body-temp-path=/var/lib/nginx/body     \
            --http-proxy-temp-path=/var/lib/nginx/proxy          \
            --http-fastcgi-temp-path=/var/lib/nginx/fastcgi      \
            --http-scgi-temp-path=/var/lib/nginx/scgi            \
            --http-uwsgi-temp-path=/var/lib/nginx/uwsgi          \
            --user=nginx                                         \
            --group=nginx                                        \
            --with-threads                                       \
            --with-file-aio                                      \
            --with-pcre-jit                                      \
            --with-http_ssl_module                               \
            --with-http_v2_module                                \
            --with-http_realip_module                            \
            --with-http_gzip_static_module                       \
            --with-http_stub_status_module                       \
            --without-http_ssi_module

make

# `make install` will not overwrite an existing nginx.conf, which is what makes this
# recipe re-runnable against a machine whose config came from its overlay: auto/install
# generates the rule as `test -f <conf> || cp conf/nginx.conf <conf>`. The same guard
# covers mime.types, fastcgi.conf and the fastcgi/scgi/uwsgi params files -- so a
# version bump does NOT refresh them in place. What it does do is write a
# `<name>.default` copy of each one unconditionally (mime.types.default,
# nginx.conf.default, ...), which is where to look for what changed upstream between
# releases. Only koi-win/koi-utf/win-utf are copied over unconditionally.
make install

# Relocate nginx's own two sample pages out of /usr/html.
#
# `make install` hardcodes this one path: auto/install emits
# `test -d '$(DESTDIR)/usr/html' || cp -R html '$(DESTDIR)/usr'`, always $NGX_PREFIX/html,
# and unlike every other path there is no configure flag to redirect it (there is no
# --html-path). With --prefix=/usr that lands index.html and 50x.html in /usr/html,
# which is not a directory the FHS has any place for -- and because lfsmaint records the
# manifest of what a step installed, leaving it there means /usr/html is reported as
# owned by nginx for the life of the system.
#
# Moved to /usr/share/nginx/html, which is where the distributions put it and where a
# config's `root` or `error_page` can reasonably point. Only 50x.html is kept: it is a
# usable generic error page, whereas upstream's index.html is the "Welcome to nginx!"
# placeholder, and this recipe writes a more informative one into /srv/www/nginx below.
if [ -d /usr/html ]; then
    install -v -d -o root -g root -m 0755 /usr/share/nginx/html
    install -v -o root -g root -m 0644 /usr/html/50x.html /usr/share/nginx/html/50x.html
    rm -rf /usr/html
fi

# Log directory. Created here as well as by the unit's LogsDirectory=nginx, so that the
# directory exists with the right mode before the very first start rather than on it.
#
# root:root and 0750, not 0755 and not root:nginx. Two things decide this:
#   - The *master* process opens every log file, and the master is root (it has to be,
#     to bind a privileged port). Workers inherit the already-open descriptors, so the
#     nginx account needs no access to this directory at all -- verified on the running
#     service, whose workers log fine with the directory unreadable to them.
#   - systemd would override a group of nginx anyway: LogsDirectory chowns to the
#     service's User=/Group=, and this unit has neither, so it resolves to root:root.
#     Setting -g nginx here would just be silently undone on the next start, so the
#     recipe states what will actually be true.
# 0750 because an access log on a file server records who fetched what.
install -v -d -o root -g root -m 0750 /var/log/nginx

# Scratch directories for buffered request bodies and upstream responses. Written by
# the *workers*, so they are owned by nginx and mode 0700 -- a client body spooled to
# disk here is the content of somebody's upload.
install -v -d -o root  -g root  -m 0755 /var/lib/nginx
for d in body proxy fastcgi scgi uwsgi; do
    install -v -d -o nginx -g nginx -m 0700 /var/lib/nginx/$d
done

# Default configuration. This is a stub, and it is meant to be: a real nginx.conf names
# a docroot and a listen address, and both of those are per-machine facts that CLAUDE.md
# puts in the host, not in a shared recipe. A host's real config lives in
# hosts/<h>/overlay/etc/nginx/nginx.conf and is applied at deploy time.
#
# So the stub is chosen to fail safe rather than to be useful: loopback only, an empty
# docroot under /srv/www/nginx, no autoindex. A machine whose overlay has not been
# applied serves a placeholder to itself and nothing to the network, instead of serving
# a directory listing of something nobody chose.
#
# Written only when absent, so neither a rebuild nor a version bump overwrites the
# config a host actually runs -- the same guard BLFS's own config steps use on /etc.
install -v -d /etc/nginx
install -v -d -o root -g root -m 0755 /srv/www/nginx
if [ ! -f /srv/www/nginx/index.html ]; then
    cat > /srv/www/nginx/index.html << "ENDOFINDEX"
<!doctype html>
<title>nginx</title>
<h1>nginx is running</h1>
<p>This is the placeholder docroot installed by this system's nginx recipe. The real
configuration for this machine, if it has one, is in its overlay at
<code>hosts/&lt;host&gt;/overlay/etc/nginx/nginx.conf</code>.</p>
ENDOFINDEX
    chmod 644 /srv/www/nginx/index.html
fi

if [ ! -f /etc/nginx/nginx.conf ]; then
    cat > /etc/nginx/nginx.conf << "ENDOFCONF"
# /etc/nginx/nginx.conf -- fail-safe stub written by this system's nginx recipe.
#
# Loopback only, no autoindex, empty docroot. Replace it with this machine's own
# configuration from hosts/<host>/overlay/etc/nginx/nginx.conf; this file is not
# overwritten once it exists, so an operator edit or an applied overlay survives a
# rebuild.

user  nginx nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /run/nginx.pid;

events {
    worker_connections  1024;
    use                 epoll;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    charset       utf-8;

    # Do not advertise the running version in Server: or on error pages.
    server_tokens off;

    sendfile      on;
    tcp_nopush    on;
    tcp_nodelay   on;

    access_log    /var/log/nginx/access.log;

    server {
        listen       127.0.0.1:80;
        server_name  localhost;
        root         /srv/www/nginx;
        index        index.html;
    }
}
ENDOFCONF
    chmod 644 /etc/nginx/nginx.conf
fi

# systemd unit. Written here because the release tarball ships none: upstream's
# contrib/ has vim syntax files, a geo2nginx script and unicode tables, and no
# systemd/ or dist/ directory -- there is no nginx.service.in to install.
#
# Type=forking with an explicit PIDFile rather than Type=notify: nginx has no sd_notify
# support at all (there is no --with-systemd, and the source contains no reference to
# sd_notify), so systemd has to learn that startup finished by watching the master
# process fork and daemonise. The ExecStartPre `nginx -t` is what makes that safe: a
# config error is caught before the fork, so `systemctl start nginx` fails loudly
# instead of leaving a dead unit and an empty pidfile.
#
# KillSignal=SIGQUIT is nginx's own graceful-shutdown signal -- it lets workers finish
# the requests they are serving, which on a file server means an in-flight download of
# a large file is not cut off mid-stream. KillMode=mixed sends it to the master only,
# so the master gets to orchestrate its own workers' exit; SIGTERM to the whole group
# would kill the workers out from under it.
#
# The confinement is deliberately moderate, not maximal, and the reason is that this is
# a *shared* recipe: it cannot know where a given host's docroot is. Two settings in
# particular are left off on purpose:
#
#   ProtectHome    NOT set to yes/read-only. Serving a tree that lives under a user's
#                  home directory is a legitimate and common nginx configuration, and it
#                  is what `laptop` does. ProtectHome=yes would make that docroot vanish
#                  from the service's mount namespace and turn every request into a 404
#                  whose cause is invisible in the nginx log.
#   ProtectSystem  `full` (/usr, /boot and /etc read-only) rather than `strict`. Under
#                  `strict` the entire filesystem is read-only and every writable path
#                  has to be enumerated, which would mean this shared unit enumerating
#                  paths that only one host has.
#
# What is confined is the part that is true of any nginx: it needs a small fixed set of
# capabilities and nothing else. The master keeps CAP_NET_BIND_SERVICE (to bind :80),
# CAP_SETUID/CAP_SETGID (to drop the workers to the nginx account), CAP_CHOWN (its
# scratch and log files) and CAP_KILL (signalling its own workers on reload). Everything
# else -- module loading, raw sockets, kernel tunables, the clock, other users' processes
# -- is gone.
install -v -d /usr/lib/systemd/system
cat > /usr/lib/systemd/system/nginx.service << "ENDOFUNIT"
[Unit]
Description=nginx HTTP and reverse proxy server
Documentation=man:nginx(8) https://nginx.org/en/docs/
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -t -q
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
KillMode=mixed
# A graceful SIGQUIT waits for in-flight responses. On a server handing out large files
# that is minutes, not systemd's 90s default, and being killed at 90s would truncate a
# download rather than finish it.
TimeoutStopSec=300
Restart=on-failure
RestartSec=5

# Match worker_rlimit_nofile in the shipped configs. Each keepalive connection and each
# open file costs a descriptor, and a file server hits the 1024 default quickly.
LimitNOFILE=16384

# Recreate the log and scratch directories if they are ever removed. No
# RuntimeDirectory: --pid-path puts the pidfile at /run/nginx.pid, not under a
# /run/nginx subdirectory, and nothing else in this build writes there -- declaring it
# only created an empty directory that looked like it meant something.
LogsDirectory=nginx
LogsDirectoryMode=0750
StateDirectory=nginx

# Sandbox. See the comment block above this unit for why ProtectHome and
# ProtectSystem=strict are deliberately absent.
CapabilityBoundingSet=CAP_CHOWN CAP_KILL CAP_NET_BIND_SERVICE CAP_SETGID CAP_SETUID
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=full
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
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM

[Install]
WantedBy=multi-user.target
ENDOFUNIT
chmod 644 /usr/lib/systemd/system/nginx.service

systemctl daemon-reload

# Enable and start, the same as this project's other live-system services do from their
# own recipe (blfs-networkmanager.sh, blfs-seatd.sh, blfs-bluez.sh, blfs-tor.sh): on a
# booted native host `systemctl enable` runs for real and the WantedBy symlink is part
# of what this step installs.
systemctl enable nginx
systemctl restart nginx

echo "### version and build configuration"
/usr/sbin/nginx -V

echo "### config syntax"
/usr/sbin/nginx -t

echo "### service state"
systemctl is-enabled nginx
systemctl is-active nginx
