#!/bin/sh

#   This requires the latest rdmd in git (from 2011-05-14 or newer):
#      https://github.com/D-Programming-Language/tools
#   Then, rdmd can be compiled with DMD 2.053
#   Or, you can 'dsss build' if you have dsss, but rdmd is much faster.

rdmd -Jresources -L-lz --build-only -ofdvm/dvm/dvm -debug dvm/dvm/dvm.d
