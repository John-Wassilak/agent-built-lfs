#!/bin/bash
# SPDX-License-Identifier: MIT
# agent-built-lfs -- runtime checks for the Docker stack on a booted host
# Copyright (c) 2026 John Wassilak

# Runtime acceptance checks for the Docker stack (packages.py libseccomp, runc,
# containerd, moby, docker-cli, docker-buildx, docker-compose, tini). These are the
# checks server ran by hand after its first boot on a container-capable kernel
# (hosts/server/BUILD-REPORT.md, 2026-09-24), scripted so the next machine runs the same
# set. Nothing here names hardware, so it is shared.
#
# Needs a running dockerd, a user in the docker group (or root), network access to
# Docker Hub, and curl on the host. Pulls hello-world, alpine and nginx:alpine. Removes
# everything it creates except the alpine image, as server's run did.
#
# Usage: bin/docker-check.sh    exit status is the number of failed checks

set -u

P=lfscheck-$$
WORK=$(mktemp -d)
FAILS=0

cleanup() {
    docker rm -f "$P-nginx" >/dev/null 2>&1
    [ -f "$WORK/compose.yaml" ] &&
        docker compose -p "$P" -f "$WORK/compose.yaml" down -t 1 >/dev/null 2>&1
    docker rmi "$P-img" hello-world nginx:alpine >/dev/null 2>&1
    rm -rf "$WORK"
}
trap cleanup EXIT

# check NAME EXPECTED ACTUAL -- pass when ACTUAL contains EXPECTED
check() {
    if [[ "$3" == *"$2"* ]]; then
        printf '  pass    %s\n' "$1"
    else
        printf '  FAIL    %s\n          expected: %s\n          got:      %s\n' \
            "$1" "$2" "$(printf '%s' "$3" | tr '\n' ' ' | cut -c1-200)"
        FAILS=$((FAILS + 1))
    fi
}

run() { docker run --rm "$@" 2>&1; }

echo "== daemon =="
info=$(docker info 2>&1)
check "docker info has no WARNING lines" "none" \
    "$(grep -q WARNING <<<"$info" && grep WARNING <<<"$info" || echo none)"
check "storage driver overlayfs"   "Storage Driver: overlayfs" "$info"
check "cgroup v2, systemd driver"  "Cgroup Driver: systemd"    "$info"
check "seccomp security option"    "seccomp"                   "$info"
check "init binary has a version"  "init version: "            \
    "$(grep -E 'init version: [0-9a-f]{7}' <<<"$info")"

echo "== images and network =="
check "hello-world pulls and runs" "Hello from Docker!" "$(run hello-world)"
docker pull -q alpine >/dev/null 2>&1
check "HTTP egress from a container" "HTTP/1.1" \
    "$(run alpine wget -S -O /dev/null http://example.com/)"
check "DNS A record"    "Address:" "$(run alpine nslookup -type=a example.com | sed 1,2d)"
check "DNS AAAA record" "Address:" "$(run alpine nslookup -type=aaaa example.com | sed 1,2d)"

echo "== isolation =="
lim=$(run --memory 64m --cpus 0.5 --pids-limit 50 alpine \
    cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max /sys/fs/cgroup/pids.max)
check "memory limit 64m"  "67108864"     "$lim"
check "cpu limit 0.5"     "50000 100000" "$lim"
check "pids limit 50"     "50"           "$(tail -n1 <<<"$lim")"
check "seccomp filter mode" "Seccomp:	2" "$(run alpine grep Seccomp: /proc/self/status)"
check "unshare -U refused by the default profile" "not permitted" \
    "$(run alpine unshare -U true)"
check "device cgroup blocks an unlisted block device" "not permitted" \
    "$(run alpine sh -c 'mknod /tmp/sda b 8 0 && head -c1 /tmp/sda')"
check "--device passes a listed device" "ok" \
    "$(run --device /dev/null:/dev/xnull alpine sh -c 'echo x >/dev/xnull && echo ok')"

echo "== published ports =="
docker run -d --name "$P-nginx" -p 127.0.0.1:18080:80 -p '[::1]:18081:80' \
    nginx:alpine >/dev/null 2>&1
ip=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' "$P-nginx" 2>&1)
for _ in $(seq 20); do
    curl -so /dev/null http://127.0.0.1:18080/ && break
    sleep 0.5
done
for url in http://127.0.0.1:18080/ 'http://[::1]:18081/' "http://$ip/"; do
    check "GET $url" "200" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url")"
done

echo "== build, compose, init =="
printf 'FROM alpine\nRUN echo built-by-buildx >/built\nCMD ["cat", "/built"]\n' \
    >"$WORK/Dockerfile"
docker buildx build -q --load -t "$P-img" "$WORK" >/dev/null 2>&1
check "buildx build, then run the image" "built-by-buildx" "$(run "$P-img")"

cat >"$WORK/compose.yaml" <<'EOF'
services:
  a:
    image: alpine
    command: sleep 60
  b:
    image: alpine
    init: true
    command: sh -c 'ping -c1 -W3 a >/dev/null && echo dns-ok; cat /proc/1/comm'
EOF
docker compose -p "$P" -f "$WORK/compose.yaml" up -d a >/dev/null 2>&1
out=$(docker compose -p "$P" -f "$WORK/compose.yaml" run --rm b 2>&1)
check "compose service-name DNS (b reaches a)" "dns-ok"      "$out"
check "compose init: true runs docker-init"    "docker-init" "$out"
check "docker run --init: PID 1 is docker-init" "docker-init" \
    "$(run --init alpine cat /proc/1/comm)"
check "without --init: PID 1 is the command" "cat" "$(run alpine cat /proc/1/comm)"

echo
if [ "$FAILS" -eq 0 ]; then echo "all checks passed."; else echo "$FAILS check(s) failed."; fi
exit "$FAILS"
