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

# Installs the specified version of the compiler
# $1 = the DVM install directory
# $2 = the version of the compiler to install
dvm_install() {
  local dvm_install_dir="$1"
  local version="$2"

  HOME="$dvm_install_dir"
  USERPROFILE="$dvm_install_dir"
  APPDATA="$dvm_install_dir"

  source "$dvm_install_dir/.dvm/scripts/dvm"

  HOME="$dvm_install_dir" \
    USERPROFILE="$dvm_install_dir" \
    APPDATA="$dvm_install_dir" \
    dvm install "$version"
}

platform() {
  local system="$(uname -s)"

  case "$system" in
    Darwin)
      echo 'osx'
      ;;

    Linux)
      echo 'linux'
      ;;

    FreeBSD)
      echo 'freebsd'
      ;;

    *)
      echo "Unrecognized operating system: $system"
      return 1
      ;;
  esac
}
