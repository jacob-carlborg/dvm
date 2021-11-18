# Installs DVM and returns the install directory
dvm_install_dvm() {
  local dvm_install_dir="$(mktemp -d -t dvm_test_home)"

  mkdir -p "$dvm_install_dir"

  HOME="$dvm_install_dir" \
    USERPROFILE="$dvm_install_dir" \
    APPDATA="$dvm_install_dir" \
    "$DVM_ROOT/bin/dvm" install dvm > /dev/null

  echo "$dvm_install_dir"
}
