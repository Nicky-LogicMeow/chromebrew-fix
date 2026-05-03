#!/usr/bin/env bash
# Chromebrew installer wrapper: git 2.54.0 x86_64 SHA256 fix + tar/PATH fixes.
# Must be run with bash (not sh):  bash chromebrew-fix.sh
# See README.
set -e

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "chromebrew-fix: use:  bash $0" >&2
  exit 1
fi

CREW_PREFIX=/usr/local

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root. Log in as chronos and try again." >&2
  exit 1
fi

echo "chromebrew-fix: starting..." >&2

crew_fix_environment() {
  if [[ ! -d "$CREW_PREFIX" ]]; then
    sudo mkdir -p "$CREW_PREFIX" || {
      echo "chromebrew-fix: could not create $CREW_PREFIX (sudo / developer mode?)" >&2
      exit 1
    }
  fi
  sudo chown -R "$(id -u)":"$(id -g)" "$CREW_PREFIX" 2>/dev/null || true

  local sys_tar=""
  for candidate in /usr/bin/tar /bin/tar; do
    if [[ -x "$candidate" ]]; then
      sys_tar="$candidate"
      break
    fi
  done
  if [[ -n "$sys_tar" ]]; then
    sudo mkdir -p "$CREW_PREFIX/bin" || true
    sudo rm -f "$CREW_PREFIX/bin/tar" 2>/dev/null || true
    sudo ln -sf "$sys_tar" "$CREW_PREFIX/bin/tar" || {
      echo "chromebrew-fix: warning: could not symlink $CREW_PREFIX/bin/tar → $sys_tar" >&2
    }
    sudo chown -h "$(id -u)":"$(id -g)" "$CREW_PREFIX/bin/tar" 2>/dev/null || true
  else
    echo "chromebrew-fix: warning: no /usr/bin/tar or /bin/tar found" >&2
  fi
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
  [[ -s /tmp/install-fixed.sh ]] || {
    echo "chromebrew-fix: /tmp/install-fixed.sh is empty (curl or awk failed?)" >&2
    exit 1
  }
}

cd "${HOME}" || cd /

export PATH="/usr/bin:/bin:${PATH}"

# Do not create anything under $CREW_PREFIX before install.sh — Chromebrew requires a clean or
# intentionally non-empty tree and will prompt (select menu) to clear if needed.

build_install_fixed

echo "chromebrew-fix: running Chromebrew install.sh (use keyboard when it asks questions) ..." >&2
# Chromebrew uses `select` for /usr/local clear; stdin must be the terminal, not a pipe from curl.
bash /tmp/install-fixed.sh </dev/tty

crew_fix_environment

# Do not let a missing or strict .bashrc kill the script after a successful install.
if [[ -f "${HOME}/.bashrc" ]]; then
  set +e
  # shellcheck disable=SC1090
  . "${HOME}/.bashrc"
  set -e
fi

echo "chromebrew-fix: finished. If crew is not found, open a new shell or run:  source ~/.bashrc" >&2
