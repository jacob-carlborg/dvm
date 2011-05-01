#!/bin/sh

if [[ -z "$dvm_prefix" ]] ; then

	if [[ -n "$HOME" ]] ; then
		dvm_prefix="$HOME/."
	else
		echo "No \$dvm_prefix was provided and "
		echo "$(id | \sed -e's/^[^(]*(//' -e 's/).*//') has no \$HOME defined."
		echo "Exiting..."
		return 1
	fi
fi

if [[ -z "$dvm_path" ]] ; then
	dvm_path="${dvm_prefix}dvm"
fi

__dvm_setup_paths()
{
	dvm_tmp_path="$dvm_path/tmp"
	dvm_result_path="$dvm_tmp_path/result"
	dvm_bin_path="$dvm_path/bin"
	dvm_exe_path="$dvm_bin_path/dvm"
	dvm_default_path="$dvm_path/env/default"
}

__dvm_setup_environment()
{
	PATH="$dvm_bin_path:$PATH"
	PATH=$PATH
}

__dvm_setup_paths
__dvm_setup_environment

dvm()
{	
	if [[ -e "$dvm_exe_path" ]] ; then
		"$dvm_exe_path" "$@"
	else
		echo "Cannot found the dvm executable \"$dvm_exe_path\""
		echo "Exiting..."
		return 1
	fi
	
	if [[ -s "$dvm_result_path" ]] ; then
		. "$dvm_result_path"
	fi

	if [[ -s "$dvm_tmp_path" ]] ; then
		rm -r "$dvm_tmp_path"
	fi
}

if [[ -s "$dvm_default_path" ]] ; then
	. "$dvm_default_path"
fi

unset __dvm_setup_paths __dvm_setup_environment