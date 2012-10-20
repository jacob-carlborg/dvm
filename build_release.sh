#!/bin/sh

if [ -s "$HOME/.dvm/scripts/dvm" ] ; then
    . "$HOME/.dvm/scripts/dvm" ;
    dvm use 1.072
fi

rdmd -Jresources -L-lz --build-only -ofbin/dvm -release -O -inline "$@" dvm/dvm/dvm.d
