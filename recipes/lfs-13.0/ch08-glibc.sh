#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter08/glibc.html
# title  : 8.5. Glibc-2.43
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: ing and closing files, reading and writing files, string handling, pattern matching,
#   ctx: arithmetic, and so on. Approximate build time: 12 SBU Required disk space: 3.5 GB 8.5.1.
#   ctx: Installation of Glibc Some of the Glibc programs use the non-FHS compliant /var/db
#   ctx: directory to store their runtime data. Apply the following patch to make such programs
#   ctx: store their runtime data in the FHS-compliant locations:
patch -Np1 -i ../glibc-fhs-1.patch

# --- block 1 --------------------------------------------------
#   ctx: The Glibc documentation recommends building Glibc in a dedicated build directory:
mkdir -v build
cd       build

# --- block 2 --------------------------------------------------
#   ctx: Ensure that the ldconfig and sln utilities will be installed into /usr/sbin:
echo "rootsbindir=/usr/sbin" > configparms

# --- block 3 --------------------------------------------------
#   ctx: Prepare Glibc for compilation:
../configure --prefix=/usr                   \
             --disable-werror                \
             --disable-nscd                  \
             libc_cv_slibdir=/usr/lib        \
             --enable-stack-protector=strong \
             --enable-kernel=5.4

# --- block 4 --------------------------------------------------
#   ctx: ack smashing attacks. Note that Glibc always explicitly overrides the default of GCC, so
#   ctx: this option is still needed even though we've already specified --enable-default-ssp for
#   ctx: GCC. --disable-nscd Do not build the name service cache daemon which is no longer used.
#   ctx: libc_cv_slibdir=/usr/lib This variable sets the correct library for all systems. We do
#   ctx: not want lib64 to be used. Compile the package:
make

# --- block 5 --------------------------------------------------
#   ctx: Important In this section, the test suite for Glibc is considered critical. Do not skip
#   ctx: it under any circumstance. Generally a few tests do not pass. The test failures listed
#   ctx: below are usually safe to ignore.
set +e
make check
__rc=$?
set -e
echo "### TESTSUITE ch08-glibc block 5 exit=$__rc (non-fatal, compare against book)"

# --- block 6 --------------------------------------------------
#   ctx: is is a list of the most common issues seen for recent versions of LFS: io/tst-lchmod is
#   ctx: known to fail in the LFS chroot environment. Some tests, for example
#   ctx: nss/tst-nss-files-hosts-multi and nptl/tst-thread-affinity* are known to fail due to a
#   ctx: timeout (especially when the system is relatively slow and/or running the test suite
#   ctx: with multiple parallel make jobs). These tests can be identified with:
#   REVIEWED [drop]: Diagnostic the book offers for spotting timed-out tests. grep exits 1 when nothing matches, which under set -e aborts the build immediately after make. Test analysis is recorded in state/testreports/ instead.
# grep "Timed out" $(find -name \*.out)

# --- block 7 --------------------------------------------------
#   ctx: -multi will re-run nss/tst-nss-files-hosts-multi with ten times the original timeout.
#   ctx: Additionally, some tests may fail with a relatively old CPU model (for example
#   ctx: elf/tst-cpu-features-cpuinfo) or host kernel version (for example
#   ctx: stdlib/tst-arc4random-thread). Though it is a harmless message, the install stage of
#   ctx: Glibc will complain about the absence of /etc/ld.so.conf. Prevent this warning with:
touch /etc/ld.so.conf

# --- block 8 --------------------------------------------------
#   ctx: Fix the Makefile to skip an outdated sanity check that fails with a modern Glibc
#   ctx: configuration:
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

# --- block 9 --------------------------------------------------
#   ctx: u need a newer Glibc. If upgrading on a LFS system prior to 12.0 (exclusive), install
#   ctx: Libxcrypt following Section 8.28, “Libxcrypt-4.5.2.” In addition to a normal Libxcrypt
#   ctx: installation, you MUST follow the note in Libxcrypt section to install libcrypt.so.1*
#   ctx: (replacing libcrypt.so.1 from the prior Glibc installation). If upgrading on a LFS
#   ctx: system prior to 12.1 (exclusive), remove the nscd program:
#   REVIEWED [drop]: Conditional on upgrading an LFS system prior to 12.1. This is a fresh build; there is no prior nscd.
# rm -f /usr/sbin/nscd

# --- block 10 --------------------------------------------------
#   ctx: If this system (prior to LFS 12.1, exclusive) is based on Systemd, it's also needed to
#   ctx: disable and stop the nscd service now:
#   REVIEWED [drop]: Same pre-12.1 upgrade condition, and systemctl cannot manage services inside the chroot.
# systemctl disable --now nscd

# --- block 11 --------------------------------------------------
#   ctx: ng Section 10.3, “Linux-6.18.10.” Upgrade the kernel API headers if it's older than 5.4
#   ctx: (check the current version with cat /usr/include/linux/version.h) or if you want to
#   ctx: upgrade it anyway, following Section 5.4, “Linux-6.18.10 API Headers” (but removing $LFS
#   ctx: from the cp command). Perform a DESTDIR installation and upgrade the Glibc shared
#   ctx: libraries on the system using one single install command:
#   REVIEWED [drop]: DESTDIR procedure for upgrading Glibc on a running system. Not applicable to a fresh build.
# make DESTDIR=$PWD/dest install
# install -vm755 dest/usr/lib/*.so.* /usr/lib

# --- block 12 --------------------------------------------------
#   ctx: the sed command against /usr/bin/ldd, and the commands to install the locales. Once
#   ctx: they are finished, reboot the system immediately. When the system has successfully
#   ctx: rebooted, if you are running a LFS system prior to 12.0 (exclusive) where GCC was not
#   ctx: built with the --disable-fixincludes option, move two GCC headers into a better location
#   ctx: and remove the stale “fixed” copies of the Glibc headers:
#   REVIEWED [drop]: Conditional on upgrading an LFS system prior to 12.0 where GCC lacked --disable-fixincludes. Not applicable.
# DIR=$(dirname $(gcc -print-libgcc-file-name))
# [ -e $DIR/include/limits.h ]    || mv $DIR/include{-fixed,}/limits.h
# [ -e $DIR/include/syslimits.h ] || mv $DIR/include{-fixed,}/syslimits.h
# rm -rfv $DIR/include-fixed/*
# unset DIR

# --- block 13 --------------------------------------------------
#   ctx: Install the package:
make install

# --- block 14 --------------------------------------------------
#   ctx: Fix a hardcoded path to the executable loader in the ldd script:
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

# --- block 15 --------------------------------------------------
#   ctx: nstalled using the localedef program. E.g., the second localedef command below combines
#   ctx: the /usr/share/i18n/locales/cs_CZ charset-independent locale definition with the
#   ctx: /usr/share/i18n/charmaps/UTF-8.gz charmap definition and appends the result to the
#   ctx: /usr/lib/locale/locale-archive file. The following instructions will install the minimum
#   ctx: set of locales necessary for the optimal coverage of tests:
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

# --- block 16 --------------------------------------------------
#   ctx: In addition, install the locale for your own country, language and character set.
#   ctx: Alternatively, install all the locales listed in the glibc-2.43/localedata/SUPPORTED
#   ctx: file (it includes every locale listed above and many more) at once with the following
#   ctx: time-consuming command:
make localedata/install-locales

# --- block 17 --------------------------------------------------
#   ctx: internationalized domain names. This is a run time dependency. If this capability is
#   ctx: needed, the instructions for installing libidn2 are in the BLFS libidn2 page. 8.5.2.
#   ctx: Configuring Glibc 8.5.2.1. Adding nsswitch.conf The /etc/nsswitch.conf file needs to be
#   ctx: created because the Glibc defaults do not work well in a networked environment. Create a
#   ctx: new file /etc/nsswitch.conf by running the following:
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# --- block 18 --------------------------------------------------
#   ctx: 8.5.2.2. Adding Time Zone Data Install and set up the time zone data with the following:
tar -xf ../../tzdata2025c.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

# --- block 19 --------------------------------------------------
#   ctx: edded system, where space is tight and you do not intend to ever update the time zones,
#   ctx: or care about the correct time, you could save 1.9MB by omitting the right directory.
#   ctx: zic ... -p ... This creates the posixrules file. We use New York because POSIX requires
#   ctx: the daylight saving time rules to be in accordance with US rules. One way to determine
#   ctx: the local time zone is to run the following script:
#   REVIEWED [drop]: tzselect is an interactive helper the book offers so a human can look up their timezone name. It blocks on a prompt and cannot run unattended.
# tzselect

# --- block 20 --------------------------------------------------
#   ctx: After answering a few questions about the location, the script will output the name of
#   ctx: the time zone (e.g., America/Edmonton). There are also some other possible time zones
#   ctx: listed in /usr/share/zoneinfo such as Canada/Eastern or EST5EDT that are not identified
#   ctx: by the script but can be used. Then create the /etc/localtime file by running:
ln -sfv /usr/share/zoneinfo/America/Chicago /etc/localtime

# --- block 21 --------------------------------------------------
#   ctx: are run. However, if there are libraries in directories other than /usr/lib, these need
#   ctx: to be added to the /etc/ld.so.conf file in order for the dynamic loader to find them.
#   ctx: Two directories that are commonly known to contain additional libraries are
#   ctx: /usr/local/lib and /opt/lib, so add those directories to the dynamic loader's search
#   ctx: path. Create a new file /etc/ld.so.conf by running the following:
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

# --- block 22 --------------------------------------------------
#   ctx: If desired, the dynamic loader can also search a directory and include the contents of
#   ctx: files found there. Generally the files in this include directory are one line specifying
#   ctx: the desired library path. To add this capability run the following commands:
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

