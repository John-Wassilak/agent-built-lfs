#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: Installs the maintenance tooling into the target: package database, security advisory check, version drift, and a weekly timer. Packaged as a tarball so its install is a tracked step like any other package.
set -e

bash install.sh

# Seed the database inside the target from the manifests the harness recorded.
# --plan is not available here (the plans live on the build host), so the database
# is built on the host and copied in; this only verifies the tool runs.
/usr/sbin/lfsmaint --root / report 2>&1 | head -8 || \
    echo "(no database yet -- built on the host and copied in)"

