d_compiler() {
  case "${DVM_COMPILER}" in
    'dmd-latest') echo 'dmd' ;;
    'ldc-latest') echo 'ldc' ;;
    'dmd-master') echo 'dmd-nightly' ;;
    'ldc-master') echo 'ldc-latest-ci' ;;
    *) echo "${DVM_COMPILER}" ;;
  esac
}

install_compiler() {
  local compiler="$(d_compiler)"
  curl -sS -L https://dlang.org/install.sh | bash -s "${compiler}"
  source "$(~/dlang/install.sh "${compiler}" -a)"
}

print_d_compiler_version() {
  "${DMD}" --version
}
