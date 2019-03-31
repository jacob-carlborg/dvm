#!/bin/bash

set -ex

function build {
  dub build --verror -b release
  strip "$target_path"
}

function version {
  "$target_path" --version
}

function arch {
  uname -m
}

function os {
  local os=$(uname | tr '[:upper:]' '[:lower:]')
  [ "$os" = 'darwin' ] && echo 'macos' || echo "$os"
}

function release_name {
  local release_name="$app_name-$(version)-$(os)"

  if [ "$(os)" = 'macos' ]; then
    echo "$release_name"
  elif [ "$(os)" = 'linux' ] && [ $TRAVIS = 'true' ]; then
    local dist=$(lsb_release -i | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
    local dist_release=$(lsb_release -r | awk '{print $2}')
    echo "$app_name-$(version)-$(os)-${dist}${dist_release}-$(arch)"
  else
    echo "$release_name-$(arch)"
  fi
}

app_name="dvm"
target_dir="bin"
target_path="$target_dir/$app_name"

build
mv "$target_path" "$target_dir/$(release_name)"
