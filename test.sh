


shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

should_install_command_line_tools() {
  if [[ -n "${HOMEBREW_ON_LINUX-}" ]]
  then
    return 1
  fi

  if version_gt "${macos_version}" "10.13"
  then
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
  else
    ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]] ||
      ! [[ -e "/usr/include/iconv.h" ]]
  fi
}

version_gt() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -gt "${2#*.}" ]]
}
version_ge() {
  [[ "${1%.*}" -gt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -ge "${2#*.}" ]]
}
version_lt() {
  [[ "${1%.*}" -lt "${2%.*}" ]] || [[ "${1%.*}" -eq "${2%.*}" && "${1#*.}" -lt "${2#*.}" ]]
}

if should_install_command_line_tools && version_ge "${macos_version}" "10.13"
then
  if ! command -v git >/dev/null 2>&1; then
    ohai "Git not found. Installing latest Git from kernel.org..."

    GIT_SRC_DIR="/tmp/git-src"
    mkdir -p "$GIT_SRC_DIR"
    cd "$GIT_SRC_DIR"

    # Get latest Git version number from kernel.org
    latest_git_version="$(curl -s https://mirrors.edge.kernel.org/pub/software/scm/git/ | \
      grep -oE 'git-[0-9]+\.[0-9]+\.[0-9]+\.tar\.xz' | \
      sort -V | tail -n1 | sed 's/git-\(.*\)\.tar\.xz/\1/')"

    if [[ -z "$latest_git_version" ]]; then
      echo "Failed to retrieve latest Git version." >&2
      exit 1
    fi

    git_tarball="git-${latest_git_version}.tar.xz"
    git_url="https://www.kernel.org/pub/software/scm/git/${git_tarball}"

    ohai "Downloading Git ${latest_git_version}..."
    curl -LO "$git_url"

    ohai "Extracting..."
    tar -xf "$git_tarball"
    cd "git-${latest_git_version}"

    ohai "Configuring and building Git..."
    make configure
    ./configure --prefix=/usr/local
    make all -j"$(sysctl -n hw.logicalcpu)"
    execute_sudo make install

    ohai "Git ${latest_git_version} installed successfully!"
    cd /
    rm -rf "$GIT_SRC_DIR"
  else
    ohai "Git is already installed, skipping installation."
  fi
else
  ohai "Skipping Git install. Version too low or not required."
fi
