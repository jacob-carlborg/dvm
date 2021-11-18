#!/usr/bin/env bash

set -eux
set -o pipefail

source "$DVM_ROOT/tests/support.sh"

dvm_install_dir=''

before() {
  dvm_install_dir="$(dvm_install_dvm)"
}

after() {
  rm -rf "$dvm_install_dir"
}

run() {
  source "$dvm_install_dir/.dvm/scripts/dvm"
  type dvm | head -n 1 | grep -q -E  '^dvm is a function$'
}

trap after EXIT
before
run
