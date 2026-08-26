#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step.
# rationale: postlfs/vimrc.html's one example is a <pre class="screen"> block (the book's own convention for 'not meant to be pasted verbatim', here just because vimrc comments use " not #) -- the extractor only captures userinput/root blocks, so this doesn't come through the normal pipeline and is quoted here by hand instead, verbatim from the book. skel.html explicitly says the /etc/skel files 'can also copy... to the home directory of any other user already in the system', root included -- root has had no .bash_profile/.bashrc/.profile/.bash_logout since the original build (chapter 4's versions were for the temporary lfs build user, not root) and was living entirely off /etc/profile + /etc/bashrc.
set -e

cat > /etc/skel/.vimrc << "EOF"
" Begin .vimrc

set columns=80
set wrapmargin=8
set ruler

" End .vimrc
EOF
chmod 600 /etc/skel/.vimrc

for f in .bash_profile .profile .bashrc .bash_logout .vimrc; do
    cp -v /etc/skel/$f /root/$f
    chown root:root /root/$f
    chmod 600 /root/$f
done

echo "### /etc/skel:"
ls -la /etc/skel
echo "### /root:"
ls -la /root/.bash_profile /root/.profile /root/.bashrc /root/.bash_logout /root/.vimrc

