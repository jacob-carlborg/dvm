@echo off

setlocal

if "%1"=="release" (
    set extra_flags=-release -O -inline
    rem remove first/handled argument
    for /f "usebackq tokens=1*" %%i in ('%*') do set args=%%j
) else (
    set extra_flags=-debug -g
)

rdmd --exclude=tango -Imambo -Jresources -L+tango -Jresources --build-only -ofbin\dvm.exe %extra_flags% %args% dvm\dvm\dvm.d

endlocal
