#!/bin/sh

if [ -s "$HOME/.dvm/scripts/dvm" ] ; then
    . "$HOME/.dvm/scripts/dvm" ;
    dvm use 2.064.2
fi

if [ "$(uname)" = "Darwin" ] ; then
    extra_linker_flags="-L-macosx_version_min -L10.6"
else
    extra_linker_flags=""
fi

rdmd -Imambo -Jresources -L-lz -L-ltango --build-only -ofbin/dvm -debug -gc $extra_linker_flags "$@" dvm/dvm/dvm.d