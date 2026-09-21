#!/bin/bash
# CANDIDATE recipe extracted from the LFS 13.0-systemd book.
# source : book/13.0/chapter09/locale.html
# title  : 9.7. Configuring the System Locale
# The driver supplies unpack/cd/cleanup. Commands below are in-package only.
# Disabled blocks are tagged with the reason; review before enabling.
set -e

# --- block 0 --------------------------------------------------
#   ctx: e, and date values Replace <ll> below with the two-letter code for your desired language
#   ctx: (e.g., en) and <CC> with the two-letter code for the appropriate country (e.g., GB).
#   ctx: <charmap> should be replaced with the canonical charmap for your chosen locale. Optional
#   ctx: modifiers such as @euro may also be present. The list of all locales supported by Glibc
#   ctx: can be obtained by running the following command:
locale -a

# --- block 1 --------------------------------------------------
#   ctx: 859-1 and iso88591. Some applications cannot handle the various synonyms correctly
#   ctx: (e.g., require that UTF-8 is written as UTF-8, not utf8), so it is the safest in most
#   ctx: cases to choose the canonical name for a particular locale. To determine the canonical
#   ctx: name, run the following command, where <locale name> is the output given by locale -a
#   ctx: for your preferred locale (en_GB.iso88591 in our example).
#   REVIEWED [drop]: 'LC_ALL=<locale name> locale charmap' is a query the book offers so a human can discover their locale name. Placeholder, not an instruction.
# LC_ALL=<locale name> locale charmap

# --- block 2 --------------------------------------------------
#   ctx: This results in a final locale setting of en_GB.ISO-8859-1. It is important that the
#   ctx: locale found using the heuristic above is tested prior to it being added to the Bash
#   ctx: startup files:
#   REVIEWED [drop]: Same class of placeholder locale queries.
# LC_ALL=<locale name> locale language
# LC_ALL=<locale name> locale charmap
# LC_ALL=<locale name> locale int_curr_symbol
# LC_ALL=<locale name> locale int_prefix

# --- block 3 --------------------------------------------------
#   ctx: ere are no such error messages from Glibc. Other packages can also function incorrectly
#   ctx: (but may not necessarily display any error messages) if the locale name does not meet
#   ctx: their expectations. In those cases, investigating how other Linux distributions support
#   ctx: your locale might provide some useful information. Once the proper locale settings have
#   ctx: been determined, create the /etc/locale.conf file:
cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
EOF

# --- block 4 --------------------------------------------------
#   ctx: it is processing a script and not waiting for user input between commands. The login
#   ctx: shells are often unaffected by the settings in /etc/locale.conf. Create the /etc/profile
#   ctx: to read the locale settings from /etc/locale.conf and export them, but set the C.UTF-8
#   ctx: locale instead if running in the Linux console (to prevent programs from outputting
#   ctx: characters that the Linux console is unable to render):
cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF

# --- block 5 --------------------------------------------------
#   ctx: Note that you can modify /etc/locale.conf with the systemd localectl utility. To use
#   ctx: localectl for the example above, run:
#   REVIEWED [drop]: localectl with a placeholder value, and it cannot reach systemd inside the chroot. Block 3 writes /etc/locale.conf directly.
# localectl set-locale LANG="<ll>_<CC>.<charmap><@modifiers>"

# --- block 6 --------------------------------------------------
#   ctx: You can also specify other language specific environment variables such as LANG,
#   ctx: LC_CTYPE, LC_NUMERIC or any other environment variable from locale output. Just separate
#   ctx: them with a space. An example where LANG is set as en_US.UTF-8 but LC_CTYPE is set as
#   ctx: just en_US is:
#   REVIEWED [drop]: localectl needs a running systemd, unavailable in the chroot.
# localectl set-locale LANG="en_US.UTF-8" LC_CTYPE="en_US"

