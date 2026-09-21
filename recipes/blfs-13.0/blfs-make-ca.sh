#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/make-ca.html
# title  : make-ca-1.16.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: following instructions to generate certificate stores from trust anchors, and each time
#   ctx: make-ca is run) Optional (runtime) nss-3.120.1 (to generate a shared NSSDB) Installation
#   ctx: of make-ca and Generation of the CA-certificates stores At first, remove the -t option
#   ctx: from the mktemp commands in the script. This option is deprecated and it can cause
#   ctx: unwanted effects if TMPDIR is set in the environment:
sed '/mktemp/s/-t //' -i make-ca

# --- block 1 --------------------------------------------------
#   ctx: es (overriding Mozilla's trust). Additionally, any modified trust values will be copied
#   ctx: from the trust anchors to /etc/ssl/local prior to any updates, preserving custom trust
#   ctx: values that differ from Mozilla when using the trust utility from p11-kit to operate on
#   ctx: the trust store. To install the various certificate stores, first install the make-ca
#   ctx: script into the correct location. As the root user:
make install &&
install -vdm755 /etc/ssl/local

# --- block 2 --------------------------------------------------
#   ctx: nd prepare for system use with the following command: Note If running the script a
#   ctx: second time with the same version of certdata.txt, for instance, to update the stores
#   ctx: when make-ca is upgraded, or to add additional stores as the requisite software is
#   ctx: installed, replace the -g switch with the -r switch in the command line. If packaging,
#   ctx: run make-ca --help to see all available command line options.
/usr/sbin/make-ca -f -C /sources/certdata.txt

# --- block 3 --------------------------------------------------
#   ctx: You should periodically update the store with the above command, either manually, or via
#   ctx: a systemd timer. A timer is installed at /usr/lib/systemd/system/update-pki.timer that,
#   ctx: if enabled, will check for updates weekly. Execute the following commands, as the root
#   ctx: user, to enable the systemd timer:
install -vdm755 /etc/systemd/system/timers.target.wants
ln -sfv /usr/lib/systemd/system/update-pki.timer /etc/systemd/system/timers.target.wants/update-pki.timer

# --- block 4 --------------------------------------------------
#   ctx: r otherwise need to create an OpenSSL trusted certificate manually from a regular PEM
#   ctx: encoded file, you need to add trust arguments to the openssl command, and create a new
#   ctx: certificate. For example, using the CAcert roots, if you want to trust both for all
#   ctx: three roles, the following commands will create appropriate OpenSSL trusted certificates
#   ctx: (run as the root user after Wget-1.25.0 is installed):
#   REVIEWED [drop]: Optional: adds the CAcert roots, which are not in Mozilla's store. Also fetches them with wget, which is not installed.
# wget http://www.cacert.org/certs/root.crt &&
# wget http://www.cacert.org/certs/class3.crt &&
# openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
#         -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#         > /etc/ssl/local/CAcert_Class_1_root.pem &&
# openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
#         -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#         > /etc/ssl/local/CAcert_Class_3_root.pem &&
# /usr/sbin/make-ca -r

# --- block 5 --------------------------------------------------
#   ctx: g Mozilla Trust Occasionally, there may be instances where you don't agree with
#   ctx: Mozilla's inclusion of a particular certificate authority. If you'd like to override the
#   ctx: default trust of a particular CA, simply create a copy of the existing certificate in
#   ctx: /etc/ssl/local with different trust arguments. For example, if you'd like to distrust
#   ctx: the "Makebelieve_CA_Root" file, run the following commands:
#   REVIEWED [drop]: The book's worked example of distrusting a CA, operating on /etc/ssl/certs/Makebelieve_CA_Root.pem -- a fictional certificate that does not exist. Would fail immediately.
# openssl x509 -in /etc/ssl/certs/Makebelieve_CA_Root.pem \
#              -text \
#              -fingerprint \
#              -setalias "Disabled Makebelieve CA Root" \
#              -addreject serverAuth \
#              -addreject emailProtection \
#              -addreject codeSigning \
#        > /etc/ssl/local/Disabled_Makebelieve_CA_Root.pem &&
# /usr/sbin/make-ca -r

# --- block 6 --------------------------------------------------
#   ctx: n configured, it is possible to make pip3 use the system certificates. The vendored
#   ctx: certificates installed in LFS are a snapshot from when the pulled-in version of Certifi
#   ctx: was created. If you regularly update the system certificates, the vendored version will
#   ctx: become out of date. To use the system certificates in Python3, you should set
#   ctx: _PIP_STANDALONE_CERT to point to them, e.g for the bash shell:
#   REVIEWED [drop]: A bare 'export _PIP_STANDALONE_CERT=...' illustrating the variable. Setting it inside a build script has no lasting effect; block 7 is the persistent version and is kept.
# export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# --- block 7 --------------------------------------------------
#   ctx: ning If you have created virtual environments, for example when testing modules, and
#   ctx: those include the Requests and Certifi modules in ~/.local/lib/python3.14/, then those
#   ctx: local modules will be used instead of the system certificates unless you remove the
#   ctx: local modules. To use the system certificates in Python3 with the BLFS profiles, add the
#   ctx: following variable to your system or personal profiles:
mkdir -pv /etc/profile.d &&
cat > /etc/profile.d/pythoncerts.sh << "EOF"
# Begin /etc/profile.d/pythoncerts.sh

export _PIP_STANDALONE_CERT=/etc/pki/tls/certs/ca-bundle.crt

# End /etc/profile.d/pythoncerts.sh
EOF

