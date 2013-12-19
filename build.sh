#!/bin/sh

if [ -s "$HOME/.dvm/scripts/dvm" ] ; then
    . "$HOME/.dvm/scripts/dvm" ;
    dvm use 2.064.2
fi

rdmd -Imambo -Jresources -L-lz -L-ltango --build-only -ofbin/dvm -debug -gc -L-macosx_version_min -L10.6 "$@" dvm/dvm/dvm.d