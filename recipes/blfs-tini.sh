#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS/SLFS/GLFS 13.1 page for tini.
# source: github.com/krallin/tini, tag v0.19.0 (commit de40ad00), GitHub archive
# tarball. Plain C, no dependencies past libc; builds offline.
#
# rationale: docker-init, the PID 1 that `docker run --init` (and compose's
# `init: true`) puts in front of the container's command so zombies get reaped and
# signals get forwarded. dockerd bind-mounts it into the container, so it has to be
# the static build: the container's own libc, if it has one, is not the host's.
# v0.19.0 is the version moby 29.8.1 pins (hack/dockerfile/install/tini.installer,
# Dockerfile TINI_VERSION). Added 2026-09-23 after the post-reboot check found
# `--init` failing with `exec: "docker-init": executable file not found`
# (packages.py seq 263, after the Docker stack at 256-262).
#
# The git suffix is set by hand for the same reason runc's COMMIT is: CMakeLists.txt
# asks git for it, a tarball has no .git, and the fallback is an empty string. dockerd
# reads the commit out of `docker-init --version` ("tini version 0.19.0 - git.de40ad0",
# daemon/info_unix.go parseInitVersion), so without it `docker info` shows a blank
# "init version".
#
# CMAKE_POLICY_VERSION_MINIMUM=3.5: CMakeLists.txt declares cmake_minimum_required
# 2.8, which CMake 4 refuses. Same workaround moby's installer applies.
#
# Installed as /usr/libexec/docker/docker-init, the second directory in dockerd's
# lookup order (daemon/config/config_linux.go lookupBinPath) and next to the CLI
# plugins. Only tini-static is built; the dynamic `tini` has no user here.
set -e

sed -i 's/set(tini_VERSION_GIT "")/set(tini_VERSION_GIT " - git.de40ad0")/' CMakeLists.txt

mkdir build
cd build
cmake -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -D CMAKE_BUILD_TYPE=Release       \
      ..
make tini-static

install -v -d -m755 /usr/libexec/docker
install -v -m755 tini-static /usr/libexec/docker/docker-init

echo "### version"
/usr/libexec/docker/docker-init --version
file /usr/libexec/docker/docker-init
