#!/bin/bash
# Chromebrew installer wrapper: git 2.54.0 x86_64 SHA256 fix + tar/PATH fixes.
# See README.
set -e

CREW_PREFIX=/usr/local

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root. Log in as chronos and try again."
  exit 1
fi

crew_fix_environment() {
  [[ -d "$CREW_PREFIX" ]] || sudo mkdir -p "$CREW_PREFIX"
  sudo chown -R "$(id -u)":"$(id -g)" "$CREW_PREFIX" 2>/dev/null || true

  # crew calls: system 'tar', ...  → must resolve to an executable.
  local sys_tar=""
  for candidate in /usr/bin/tar /bin/tar; do
    if [[ -x "$candidate" ]]; then
      sys_tar="$candidate"
      break
    fi
  done
  if [[ -n "$sys_tar" ]]; then
    sudo mkdir -p "$CREW_PREFIX/bin"
    if [[ -e "$CREW_PREFIX/bin/tar" ]] || [[ -L "$CREW_PREFIX/bin/tar" ]]; then
      sudo rm -f "$CREW_PREFIX/bin/tar"
    fi
    sudo ln -sf "$sys_tar" "$CREW_PREFIX/bin/tar"
    sudo chown -h "$(id -u)":"$(id -g)" "$CREW_PREFIX/bin/tar" 2>/dev/null || true
  fi
}

clear_crew_prefix_contents() {
  # Remove everything inside /usr/local (including hidden top-level entries).
  # GNU find -delete can fail on some trees; rm -rf each child is more reliable.
  [[ -d "$CREW_PREFIX" ]] || return 0
  sudo find "$CREW_PREFIX" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

build_install_fixed() {
  curl -fsSL https://raw.githubusercontent.com/chromebrew/chromebrew/master/install.sh -o /tmp/install.sh
  awk '
/tar -xz --strip-components=1 -C/ {
    print
    print "sed -i \"s/68ae392e60447d052a8acb171542bcd69161157b97e58f07941d476f7f6ccfc2/15e896483bc5f96cba44ad192a89788cff29ec0372b94b73f176e82857b4abb7/\" \"${CREW_LIB_PATH}/packages/git.rb\""
    next
}
{ print }' /tmp/install.sh > /tmp/install-fixed.sh
}

cd ~

export PATH="/usr/bin:/bin:${PATH}"

if [[ -d "$CREW_PREFIX" ]] && [[ -n "$(ls -A "$CREW_PREFIX" 2>/dev/null)" ]]; then
  echo ""
  echo "$CREW_PREFIX is not empty. A broken or old Chromebrew install often needs a clean folder."
  read -r -p "Delete ALL contents under $CREW_PREFIX? [y/N]: " CLEAR_REPLY < /dev/tty || true
  case "${CLEAR_REPLY,,}" in
    y|yes)
      echo "Clearing $CREW_PREFIX ..."
      clear_crew_prefix_contents
      if [[ -n "$(ls -A "$CREW_PREFIX" 2>/dev/null)" ]]; then
        echo "Warning: $CREW_PREFIX is still not empty. Try manually:"
        echo "  sudo find $CREW_PREFIX -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +"
        exit 1
      fi
      echo "Done. $CREW_PREFIX is empty."
      ;;
    *)
      echo "Keeping existing files. The installer may still prompt you later, or fail if the tree is inconsistent."
      ;;
  esac
  echo ""
fi

crew_fix_environment

build_install_fixed

bash /tmp/install-fixed.sh

crew_fix_environment
. ~/.bashrc
