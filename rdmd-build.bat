@echo off

REM   This requires the latest rdmd in git (from 2011-05-14 or newer):
REM      https://github.com/D-Programming-Language/tools
REM   Then, rdmd can be compiled with DMD 2.053
REM   Or, you can 'dsss build' if you have dsss, but rdmd is much faster.

rdmd -Jresources --build-only -ofdvm\dvm\dvm -release -O -inline dvm\dvm\dvm.d
