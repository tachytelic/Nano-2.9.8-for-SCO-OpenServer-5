#!/bin/sh
# Build GNU nano 2.9.8 natively on SCO OpenServer 5.0.7.
#
# Run this script ON the SCO machine, in a writable directory.
#
# Required:
#   GCC 3.4 or later (the SCO native 2.95.3 may also work). Set CC and
#       put it on PATH, or override via the GCC env var below.
#   /usr/gnu/bin/{gmake,gtar}, /usr/bin/patch
#   bash (used as configure shell — SCO's /bin/sh is too slow on
#       autoconf-generated scripts)
#   wget or curl
#
# Output: ./install/bin/nano — ~280 KB stripped binary.
# Dynamic deps: libcurses, libsocket, libnsl, libc — all stock SCO 5.0.7.

set -e

SCRIPT_DIR=`cd \`dirname "$0"\` && pwd`
VERSION=2.9.8
TARBALL=nano-${VERSION}.tar.gz
SRCDIR=nano-${VERSION}

if [ -n "$GCC" ]; then
    CC="$GCC"
fi
CC="${CC:-gcc}"
export CC

PATH=/usr/gnu/bin:/usr/ccs/bin:/usr/bin:/bin
export PATH

if [ ! -f "$TARBALL" ]; then
    echo "Fetching $TARBALL..."
    if which wget >/dev/null 2>&1; then
        wget --no-check-certificate "https://www.nano-editor.org/dist/v2.9/${TARBALL}"
    elif which curl >/dev/null 2>&1; then
        curl -kLO "https://www.nano-editor.org/dist/v2.9/${TARBALL}"
    else
        echo "ERROR: no wget or curl. Drop $TARBALL next to this script." >&2
        exit 1
    fi
fi

if [ ! -d "$SRCDIR" ]; then
    echo "Unpacking $TARBALL..."
    /usr/bin/gunzip -c "$TARBALL" | /usr/bin/tar xf -
fi

cd "$SRCDIR"

# Need bash for the configure script — SCO's /bin/sh (which is /bin/ksh)
# is dramatically slower than bash on autoconf-generated configure.
SHELL_BIN=`which bash 2>/dev/null`
if [ -z "$SHELL_BIN" ]; then
    echo "ERROR: bash required as configure shell." >&2
    exit 1
fi

echo "Configuring..."
# --disable-utf8 — avoid wide-char paths that need ncurses + locale support
#                  SCO doesn't have. Plain 8-bit text editing works fine.
# --disable-nls — no message catalogs (saves binary size + sidesteps
#                 SCO's broken locale).
CONFIG_SHELL=$SHELL_BIN $SHELL_BIN configure \
    --prefix="$SCRIPT_DIR/install" \
    --disable-nls \
    --disable-utf8 \
    CC="$CC" \
    CFLAGS="-O2 -std=gnu99"

echo "Compiling..."
# -lsocket -lnsl needed for gethostname (used by files.c for lock-file
# naming). They're stock SCO libs — no external dependency added.
gmake LIBS="-lcurses -lsocket -lnsl"

echo "Installing to $SCRIPT_DIR/install/..."
gmake install

echo "Stripping..."
strip "$SCRIPT_DIR/install/bin/nano" 2>/dev/null || true

ls -l "$SCRIPT_DIR/install/bin/nano"
echo
echo "Test it:"
echo "  $SCRIPT_DIR/install/bin/nano -V"
echo "  $SCRIPT_DIR/install/bin/nano /tmp/somefile.txt"
echo
echo "To package: gtar czf nano-${VERSION}-sco.tar.gz install"
