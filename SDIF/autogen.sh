#!/bin/sh

# unset some stuff that disturbs the tools
PERLLIB=
PERL5LIB=
PERLSITE=
PERLARCH=
export PERLLIB PERL5LIB PERLSITE PERLARCH

# display versions
echo "[auto-tools versions in your path on $HOST]"
for f in aclocal automake autoconf autoheader autom4te libtoolize; do
    echo -n `$f --version | head -1` ": "
    ls -lFgG `which $f`
done

rm -rf aclocal.m4 config.* install-sh libtool ltconfig ltmain.sh missing mkinstalldirs autom4te.cache

set -x

aclocal
# On Mac OS X, libtoolize is glibtoolize
glibtoolize --force --automake --copy || libtoolize --force --automake --copy
autoheader
autoconf
automake --foreign --add-missing --copy
