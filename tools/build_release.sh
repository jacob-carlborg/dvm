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
  else
    echo "$release_name-$(arch)"
  fi
}

app_name="dvm"
target_dir="bin"
target_path="$target_dir/$app_name"

build
mv "$target_path" "$target_dir/$(release_name)"
