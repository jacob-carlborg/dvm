#!/bin/sh

if [ -s "$HOME/.dvm/scripts/dvm" ] ; then
    . "$HOME/.dvm/scripts/dvm" ;
    dvm use 1.072
fi

rdmd -Jresources -L-lz --build-only -ofbin/dvm -debug -L-macosx_version_min -L10.6 "$@" dvm/dvm/dvm.d
