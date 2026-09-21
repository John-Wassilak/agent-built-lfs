#!/bin/bash
# CANDIDATE recipe extracted from the BLFS 13.0-systemd book.
# source : book/blfs-13.0/postlfs/fuse.html
# title  : Fuse-3.18.1
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
set -e

# --- block 0 --------------------------------------------------
#   ctx: Installation of Fuse Install Fuse by running the following commands:
sed -i '/^udev/,$ s/^/#/' util/meson.build &&

mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release .. &&
ninja

# --- block 1 --------------------------------------------------
#   ctx: The API documentation is included in the package, but if you have Doxygen-1.16.1
#   ctx: installed and wish to rebuild it, issue:
#   REVIEWED [drop]: Optional API-doc rebuild ('if you have Doxygen installed and wish to rebuild it') -- doxygen is not part of this build. Same class as every other doc-tool trap in this project (json-c, gdk-pixbuf, pango, popt, libassuan, gnupg, ffmpeg, libnotify, libevent).
# pushd .. &&
#   doxygen doc/Doxyfile &&
# popd

# --- block 2 --------------------------------------------------
#   ctx: To test the results, issue the following commands (as the root user):
#   REVIEWED [drop]: The test suite (python3 venv + pytest) -- skipped, matches every other package in this build. Needs pytest-9.0.2 and looseversion, neither installed.
# python3 -m venv --system-site-packages testenv &&
# source testenv/bin/activate                    &&
# pip3 install looseversion                      &&
# python3 -m pytest
# deactivate

# --- block 3 --------------------------------------------------
#   ctx: The pytest-9.0.2 Python module is required for the tests. One test named test_cuse will
#   ctx: fail if the CONFIG_CUSE configuration item was not enabled when the kernel was built.
#   ctx: One test, test/util.py, will output a warning due to the usage of an unknown mark in
#   ctx: pytest. Now, as the root user:
ninja install                  &&
chmod u+s /usr/bin/fusermount3 &&

cd ..                          &&
cp -Rv doc/html -T /usr/share/doc/fuse-3.18.1 &&
install -v -m644   doc/{README.NFS,kernel.txt} \
                   /usr/share/doc/fuse-3.18.1

# --- block 4 --------------------------------------------------
#   ctx: ildtype suitable for stable releases of the package, as the default may produce
#   ctx: unoptimized binaries. --system-site-packages: Allow the Python3 venv module to access
#   ctx: the system-installed /usr/lib/python3.14/site-packages directory. Configuring fuse
#   ctx: Config Files Some options regarding mount policy can be set in the file /etc/fuse.conf.
#   ctx: To install the file run the following command as the root user:
cat > /etc/fuse.conf << "EOF"
# Set the maximum number of FUSE mounts allowed to non-root users.
# The default is 1000.
#
#mount_max = 1000

# Allow non-root users to specify the 'allow_other' or 'allow_root'
# mount options.
#
#user_allow_other
EOF

