@echo off

set dvm_prefix=%APPDATA%\
set dvm_path=%dvm_prefix%dvm

set dvm_tmp_path=%dvm_path%/tmp
set dvm_result_path=%dvm_tmp_path%/result.bat
set dvm_bin_path=%dvm_path%/bin
set dvm_exe_path=%dvm_bin_path%/_dvm.exe
set dvm_default_env_path=%dvm_path%/env/default
set dvm_default_bin_path=%dvm_bin_path%/dvm-default-dc
set dvm_current_path=%dvm_bin_path%/dvm-current-dc

REM if exist "%dvm_exe_path%" (
REM 	call "%dvm_default_env_path%"
REM )

REM if exist "%dvm_default_bin_path%" (
REM 	copy /Y "%dvm_default_bin_path%" "%dvm_current_path%" > NUL
REM )

if exist "%dvm_exe_path%" (
	"%dvm_exe_path%" %*
)

if exist "%dvm_result_path%" (
	call "%dvm_result_path%"
	
	REM Prevent result.bat from accedentally being rerun next time dvm.bat is run
	move /Y "%dvm_result_path%" "old_%dvm_result_path%"
)

del /Q /F /S "%dvm_tmp_path%" > NUL
