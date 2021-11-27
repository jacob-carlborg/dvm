#!/usr/bin/env bash

set -eu
set -o pipefail

. ./tools/install_dc.sh

if [ -z ${DVM_DOCKER+default} ]; then
  docker=false
else
  docker=true
fi

install_c_compiler() {
  if "$docker" && ! command -v cc > /dev/null; then
    apk add build-base --no-cache
  fi
}

install_dc() {
  install_compiler
  print_d_compiler_version
}

build() {
  dub build
}

run_tests() {
  ./test.sh
}

install_c_compiler
install_dc
build
run_tests
