#!/bin/sh
# TODO Documentation and cleanup
set -e
. rpg-sh-setup

[ "$*" ] || set -- '--help'; ARGV="$@"
USAGE '${PROGNAME} [-f] <package> [[-v] <version>] ...
       ${PROGNAME} [-f] <package>[/<version>]...
       ${PROGNAME} [-f] -s <name>
Install packages into rpg environment.

Options
  -f          Force package installation even if already installed
  -s <name>   Install from a session created with rpg-prepare'

session=default
force=false
while getopts fs: opt
do case $opt in
   s)   session="$OPTARG";;
   f)   force=true;;
   ?)   helpthem;;
   esac
done
shift $(( $OPTIND - 1 ))

sessiondir="$RPGSESSION/$session"
packlist="$sessiondir/package-list"
delta="$sessiondir/delta"
solved="$sessiondir/solved"

test "$session" = "default" -a -d "$sessiondir" && {
    notice "rm'ing crusty session dir: $sessiondir"
    rm -rf "$sessiondir"
}

if $force
then packageinstallargs=-f
     installfrom="$solved"
else packageinstallargs=
     installfrom="$delta"
fi

if expr "$1" : '.*\.gem' >/dev/null
then file="$1"
     test -r "$file" || {
        warn "gem file can not be read: $file"
        exit 1
     }
     rpg-unpack -cm "$file"       |
     rpg-package-spec -           |
     grep '^dependency: runtime ' |
     cut -d ' ' -f 3-
fi

exit

test -d "$sessiondir" || {
    trap "rm -rf '$sessiondir'" 0
    rpg-prepare -i -s "$session" "$@"
}

numpacks=$(grep -c . <"$installfrom")
if $force
then heed "installing $numpacks packages (forced)"
else heed "installing $numpacks packages"
fi

<"$installfrom" xargs -n 2 rpg-package-install $packageinstallargs

heed "installation complete"

true
