#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/server/openldap.html
# title  : OpenLDAP-2.6.12
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: nixODBC-2.3.14, MariaDB-11.8.6 or PostgreSQL-18.2 or MySQL, OpenSLP, WiredTiger, and
#   ctx: Berkeley DB (deprecated) (for slapd, also deprecated) Installation of OpenLDAP Note If
#   ctx: you only need to install the client side ldap* binaries, corresponding man pages,
#   ctx: libraries and header files (referred to as a “client-only” install), issue these
#   ctx: commands instead of the following ones (no test suite available):
patch -Np1 -i ../openldap-2.6.12-consolidated-1.patch &&
autoconf &&

./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --disable-static  \
            --enable-dynamic  \
            --disable-debug   \
            --disable-slapd   &&

make depend &&
make

# --- block 1 --------------------------------------------------
#   ctx: Then, as the root user:
make install

# --- block 2 --------------------------------------------------
#   ctx: There should be a dedicated user and group to take control of the slapd daemon after it
#   ctx: is started. Issue the following commands as the root user:
#   REVIEWED [drop]: Creates the ldap system user/group for a running slapd daemon. Not installing slapd (client-only build above).
# groupadd -g 83 ldap &&
# useradd  -c "OpenLDAP Daemon Owner" \
#          -d /var/lib/openldap -u 83 \
#          -g ldap -s /bin/false ldap

# --- block 3 --------------------------------------------------
#   ctx: Install OpenLDAP by running the following commands:
#   REVIEWED [drop]: The full server build (--enable-slapd and the rest) -- superseded by the client-only build in blocks 0-1.
# patch -Np1 -i ../openldap-2.6.12-consolidated-1.patch &&
# autoconf &&
# 
# ./configure --prefix=/usr         \
#             --sysconfdir=/etc     \
#             --localstatedir=/var  \
#             --libexecdir=/usr/lib \
#             --disable-static      \
#             --disable-debug       \
#             --with-tls=openssl    \
#             --with-cyrus-sasl     \
#             --without-systemd     \
#             --enable-dynamic      \
#             --enable-crypt        \
#             --enable-spasswd      \
#             --enable-slapd        \
#             --enable-modules      \
#             --enable-rlookups     \
#             --enable-backends=mod \
#             --disable-sql         \
#             --disable-wt          \
#             --enable-overlays=mod &&
# 
# make depend &&
# make

# --- block 4 --------------------------------------------------
#   ctx: The tests are fragile, and errors may cause the tests to abort prior to finishing. Some
#   ctx: errors may happen due to timing problems. The tests take around an hour, and the time is
#   ctx: CPU independent due to delays in the tests. On most systems, the tests will run up to
#   ctx: the test065-proxyauth for mdb test. To test the results, issue: make test. Now, as the
#   ctx: root user:
#   REVIEWED [drop]: Installs and configures the full slapd server tree built by block 3, which is dropped.
# make install &&
# 
# sed -e "s/\.la/.so/" -i /etc/openldap/slapd.{conf,ldif}{,.default} &&
# 
# install -v -dm700 -o ldap -g ldap /var/lib/openldap     &&
# 
# install -v -dm700 -o ldap -g ldap /etc/openldap/slapd.d &&
# chmod   -v    640     /etc/openldap/slapd.{conf,ldif}   &&
# chown   -v  root:ldap /etc/openldap/slapd.{conf,ldif}   &&
# 
# install -v -dm755 /usr/share/doc/openldap-2.6.12 &&
# cp      -vfr      doc/{drafts,rfc,guide} \
#                   /usr/share/doc/openldap-2.6.12

# --- block 5 --------------------------------------------------
#   ctx: e. The slapd.conf(5) and slapd-config(5) man pages. The OpenLDAP 2.6 Administrator's
#   ctx: Guide (also installed locally in /usr/share/doc/openldap-2.6.12/guide/admin). Documents
#   ctx: located at https://www.openldap.org/pub/. Systemd Unit To automate the startup of the
#   ctx: LDAP server at system bootup, install the slapd.service unit included in the
#   ctx: blfs-systemd-units-20251204 package using the following command:
#   REVIEWED [drop]: 'make install-slapd' is a blfs-systemd-units target, not openldap's own -- same situation as sshd.service/iptables.service. Moot anyway: no slapd server is being installed.
# make install-slapd

# --- block 6 --------------------------------------------------
#   ctx: Note You'll need to modify /etc/default/slapd to include the parameters needed for your
#   ctx: specific configuration. See the slapd man page for parameter information. Testing the
#   ctx: Configuration Start the LDAP server using systemctl:
#   REVIEWED [drop]: Starts the slapd server via systemctl. Not installing slapd.
# systemctl start slapd

# --- block 7 --------------------------------------------------
#   ctx: Verify access to the LDAP server with the following command:
#   REVIEWED [drop]: Tests a running slapd server. Not installing slapd.
# ldapsearch -x -b '' -s base '(objectclass=*)' namingContexts

