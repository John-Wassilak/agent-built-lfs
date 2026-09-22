#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# source : LFS chapter 7 "Creating Essential Files", block 6. Verified 2026-09-22 to
# be byte-identical in LFS 13.0 and 13.1, so this file is correct for both hosts and
# stays shared.
# rationale: Remediation. ch07-createfiles block 5 was `exec /usr/bin/bash --login`, which replaced the shell and silently discarded block 6 -- the block that creates the login-accounting files. Re-running ch07-createfiles is NOT safe now: its `cat > /etc/passwd` would delete the sshd user OpenSSH added and re-add the tester account ch08-cleanup removed. So apply just the lost block.
set -e

# Exactly block 6 of LFS 13.0 section 7.6, and nothing else.
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

echo "### login accounting files:"
ls -l /var/log/{btmp,lastlog,faillog,wtmp}

