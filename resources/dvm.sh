#!/bin/sh

if [ -z ${dvm_prefix:+default} ] ; then

    if [ -n "$HOME" ] ; then
        dvm_prefix="$HOME/."
    else
        echo "No \$dvm_prefix was provided and "
        echo "$(id | \sed -e's/^[^(]*(//' -e 's/).*//') has no \$HOME defined."
        echo "Exiting..."
        return 1
    fi
fi

dvm_path=${dvm_path:-${dvm_prefix}dvm}

__dvm_setup_paths()
{
    dvm_tmp_path="$dvm_path/tmp"
    dvm_result_path="$dvm_tmp_path/result"
    dvm_bin_path="$dvm_path/bin"
    dvm_exe_path="$dvm_bin_path/dvm"
    dvm_default_env_path="$dvm_path/env/default"
    dvm_default_bin_path="$dvm_bin_path/dvm-default-dc"
    dvm_current_path="$dvm_bin_path/dvm-current-dc"
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
    if [ -e "$dvm_exe_path" ] ; then
        "$dvm_exe_path" "$@"
        exit_code=$?
    else
        echo "Cannot found the dvm executable \"$dvm_exe_path\""
        echo "Exiting..."
        return 1
    fi

    if [ -s "$dvm_result_path" ] ; then
        . "$dvm_result_path"
    fi

    if [ -s "$dvm_tmp_path" ] ; then
        rm -r "$dvm_tmp_path"
    fi

    return $exit_code
}

if [ -s "$dvm_default_env_path" ] ; then
    . "$dvm_default_env_path"
fi

if [ -s "$dvm_default_bin_path" ] ; then
    cp "$dvm_default_bin_path" "$dvm_current_path"
fi

unset __dvm_setup_paths __dvm_setup_environment
