#!/bin/sh

if [ -s "$HOME/.dvm/scripts/dvm" ] ; then
    . "$HOME/.dvm/scripts/dvm" ;
    dvm use 2.066.1
fi

if [ "$(uname)" = "Darwin" ] ; then
    extra_linker_flags="-L-macosx_version_min -L10.6"
else
    extra_linker_flags=""
fi

if [ "$1" = "release" ] ; then
    extra_flags="-release -O -inline"
    shift
else
    extra_flags="-debug -g"
fi

${RDMD:-rdmd} --exclude=tango -Imambo -Jresources -L-lz -L-ltango --build-only -ofbin/dvm $extra_flags $extra_linker_flags "$@" dvm/dvm/dvm.d
