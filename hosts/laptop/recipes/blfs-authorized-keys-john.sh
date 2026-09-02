#!/bin/bash
# HAND-AUTHORED recipe -- no BLFS book page covers this step. Host-specific (not a
# shared recipe): the key material below is real, current authorized_keys content
# copied directly from the live host's ~/.ssh/authorized_keys (public keys, safe to
# carry -- private keys never leave the live host and are not part of this build).
# rationale: requested alongside disabling SSH password authentication
# (blfs-overrides.json, blfs-openssh block 5) -- without this, key-only auth would
# lock out all SSH access, since no authorized_keys existed anywhere in this build.
set -e

install -v -d -m700 -o john -g john /home/john/.ssh

cat > /home/john/.ssh/authorized_keys << "EOF"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD1NGVd80XYR9pTsrIA75Mb/dC7ZFDBl6X7UoSh9EeVFM1QBAOOhkunBQbV9PPYWKfU1bmDCDCzlbsQoV3CXMI4zVBm/7eUYnwQ6IyYc7BEnONErobgzmVC5PGrw7IPvfhMcuVZdomtm3hUTOBUtI+yhhAontsj7Z8eFMrbGPPQLUfVgRBeQ/rf8FN3aynIn/u/KrFZ+0N+Ji+Sge5qH37iPSaCUXXcIgTVqi2tjyowgJbWjmmXM5bnxyyEatiiKDwVPxxvfRDfKS35uNyGYEYtZuz2QsgAKxzIwvlIa6/7fq+oKGKTQSq2h8eT7W7bvNiyORgSggezU5Wc1S0W/DOyYfUNuzZfxkEpdfNN4rUAetKN1UPlBQRmc4IMDS5IbeNNjh57E1ZW7xGkR0Szcm0B/QFC0pesKdkJVtBFDfKktKVSf8qhZjxTSqRy2JnNvrzHSEfadjCnzg4B1ktsZATYpszIbxui5JvzyrP1lNrUAfyA0wAmwKddukEuPF/SXuXLJAV8UWMrJIzlLJAcHtbGG9t8EHoemHGe+4FS6Dg64AqccIZFnMJDAp6FL3+L8Yepl6pF/JR1RW9JerqgFWluJnO218zg50esx1eRbgj6gVivJvRD9ZKAsh37ivF8Lgj6mN0oDS0JYxuSrbCuKFiY/tESTCNf/EoukRL1sPbBeQ== john@pi-tv
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0yVrcib4uauXYSzBomNBdnK36MrV7SLs3qKNAbVHH7Vg9BNAq+lnowRnt/G5KVQPxwvGwmRIR3saF23338/cn3/F3QGDN/Rn0HwTWc3dH5zbqs+V+45K0xkpIT847Kj9O28+cNxbwPHjGq1q20RiitJuCEJ1vkjTVzDB1oa1sIGLjme2Pi7Fxem88ZGMEPtulietnxAZ1Al9mWAK7T8NXD4geNjH7R6xdcBAWQrKQVpLw4t9mzJnHbUygdR0L5I41GiHJNjCSjyZlmHC5iQoK9csVKZ7k1i1wA6vCu6LUfDaQS8kPhXaWqoEpY/u8Ds0b8XLdK+6gFPSgBdzXbaRSa/cp/0j0YraWA6Qf/hStCGZZhhzs1o2k9b3rYZ7puBhanag6zHWp+p8Afj1oTDdhY5Xed9KThUn0qg2piaMrjDQtv1Zv/sUXeMppzN/edlGIG06K14hrpfDzeJ+GZ0WzvvAfwbou69S4qpi/hVWQxBXBwFY8E4ffmtS52gxN4tgwBKzJn7oIaZQkVJQVAW7RprkA/halZN0PxM1U4369aHJD0H5ofb+L/j8WtYr4K1N3IavsAPpZ2Wc0plniyUoNi/p6ZywEVyQwWrWXnQ2G68SpubYTMASWtKg7cq6yek+JruifrUPcYJtbzNF9nYeE2s5Y66fPAS9KEaoFnopa9Q== john@pi-master-tv
EOF

chown john:john /home/john/.ssh/authorized_keys
chmod 600 /home/john/.ssh/authorized_keys

echo "### authorized_keys installed:"
wc -l /home/john/.ssh/authorized_keys
