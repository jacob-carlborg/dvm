#!/usr/bin/env bash

set -eu
set -o pipefail

has_argument() {
  local term="$1"
  shift
  for arg; do
    if [ $arg == "$term" ]; then
      return 0
    fi
  done

  return 1
}

main() {
  export DVM_ROOT="$(pwd)"


  find tests -name test.sh -print0 | {
    local failed=0

    while IFS= read -r -d '' line; do
      pushd $(dirname "$line") > /dev/null
      echo "********** Running tests in: $(pwd)"

      local output

      if has_argument "--verbose" "$@"; then
        if ! ./test.sh; then
          failed=1
          echo 'Test failed'
        fi
      else
        if ! output="$(./test.sh 2>&1)"; then
          failed=1
          echo 'Test failed with output:'
          echo "$output"
        fi
      fi

      popd > /dev/null
    done

    return "$failed"
  }
}

main "$@"
