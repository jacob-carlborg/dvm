@echo off

rdmd -Imambo -Jresources -L+tango -Jresources --build-only -ofbin\dvm.exe -debug %* dvm\dvm\dvm.d