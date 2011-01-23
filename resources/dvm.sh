#!/usr/bin/env bash

# Set the default sandboxed value.
if [[ -z "${dvm_selfcontained:-""}" ]] ; then
	if [[ $(id | \sed -e 's/(.*//' | awk -F= '{print $2}') -eq 0 || \
			-n "$dvm_prefix" && "$dvm_prefix" != "$HOME"/* ]] ; then

		dvm_selfcontained=0
	else
		dvm_selfcontained=1
	fi
fi

if [[ -z "$dvm_prefix" ]] ; then

	if [[ "$dvm_selfcontained" = "0" ]] ; then
		dvm_prefix="/usr/local/"
	elif [[ -n "$HOME" ]] ; then
		dvm_prefix="$HOME/."
	else
		echo "No \$dvm_prefix was provided and "
		echo "$(id | \sed -e's/^[^(]*(//' -e 's/).*//') has no \$HOME defined."
		echo "Exiting..."
		exit 1
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
}

__dvm_setup_environment()
{
	PATH="$dvm_bin_path:$PATH"
	builtin hash -r
}

__dvm_setup_paths
__dvm_setup_environment

dvm()
{	
	if [[ -e "$dvm_exe_path" ]] ; then
		"$dvm_exe_path" "$@"
	else
		echo "Cannot found the dvm executable \"$dvm_exe_path\""
	fi
	
	if [[ -s "$dvm_result_path" ]] ; then
		source "$dvm_result_path"
		rm -r "$dvm_tmp_path"
	fi
}