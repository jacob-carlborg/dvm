#!/usr/bin/env bash

set -eu
set -o pipefail

source "$DVM_ROOT/tests/support.sh"

dvm_install_dir=''

before() {
  dvm_install_dir="$(dvm_install_dvm)"

  HOME="$dvm_install_dir"
  USERPROFILE="$dvm_install_dir"
  APPDATA="$dvm_install_dir"

  source "$dvm_install_dir/.dvm/scripts/dvm"
}

after() {
  rm -rf "$dvm_install_dir"
}

run() {
  local version="2.098.0"
  pushd "$dvm_install_dir" > /dev/null

  dvm fetch "$version"

  [ -f "dmd.$version.$(platform).zip" ]
  popd > /dev/null
}

trap after EXIT
before
run
