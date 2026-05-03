#!/bin/bash
# Chromebrew installer wrapper: git 2.54.0 x86_64 SHA256 fix + tar/PATH fixes + optional resume modes.
# See README.
set -e

CREW_PREFIX=/usr/local

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root. Log in as chronos and try again."
  exit 1
fi

# CHROMEBREW_FIX_MODE=full   — default: ask about clearing /usr/local, refresh installer, run it
# CHROMEBREW_FIX_MODE=retry  — testing: keep /usr/local, reuse /tmp/install-fixed.sh if present, run installer again
# CHROMEBREW_FIX_MODE=prep   — only fix ownership + tar + PATH; refresh patched installer if missing; do NOT run install (continue with crew yourself)
# CHROMEBREW_FIX_RESUME=1    — same as MODE=retry

CHROMEBREW_FIX_MODE="${CHROMEBREW_FIX_MODE:-full}"
if [[ -n "${CHROMEBREW_FIX_RESUME:-}" && "${CHROMEBREW_FIX_RESUME}" != "0" ]]; then
  CHROMEBREW_FIX_MODE=retry
fi

crew_fix_environment() {
  [[ -d "$CREW_PREFIX" ]] || sudo mkdir -p "$CREW_PREFIX"
  sudo chown -R "$(id -u)":"$(id -g)" "$CREW_PREFIX" 2>/dev/null || true

  # crew calls: system 'tar', ...  → must resolve to an executable. Replace a broken file with a symlink
  # to Chrome OS tar (EACCES on /usr/local/bin/tar is common after partial installs).
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

# Prefer system tar in PATH; /usr/local/bin/tar is symlinked to it by crew_fix_environment.
export PATH="/usr/bin:/bin:${PATH}"

if [[ "${CHROMEBREW_FIX_MODE}" == full ]]; then
  if [[ -d "$CREW_PREFIX" ]] && [[ -n "$(ls -A "$CREW_PREFIX" 2>/dev/null)" ]]; then
    echo ""
    echo "$CREW_PREFIX is not empty. A broken or old Chromebrew install often needs a clean folder."
    read -r -p "Delete ALL contents under $CREW_PREFIX? [y/N]: " CLEAR_REPLY < /dev/tty || true
    case "${CLEAR_REPLY,,}" in
      y|yes)
        echo "Clearing $CREW_PREFIX ..."
        sudo find "$CREW_PREFIX" -mindepth 1 -delete
        ;;
      *)
        echo "Keeping existing files. The installer may still prompt you later, or fail if the tree is inconsistent."
        ;;
    esac
    echo ""
  fi
else
  echo "chromebrew-fix: mode=${CHROMEBREW_FIX_MODE} (no /usr/local wipe prompt)."
  echo ""
fi

crew_fix_environment

if [[ -f /tmp/install-fixed.sh ]] && { [[ "${CHROMEBREW_FIX_MODE}" == retry ]] || [[ "${CHROMEBREW_FIX_MODE}" == prep ]]; }; then
  echo "chromebrew-fix: reusing existing /tmp/install-fixed.sh (delete it to regenerate from upstream)."
else
  build_install_fixed
fi

if [[ "${CHROMEBREW_FIX_MODE}" == prep ]]; then
  echo ""
  echo "Prep only (CHROMEBREW_FIX_MODE=prep): did not run the installer."
  echo "  Full install:  bash /tmp/install-fixed.sh"
  echo "  Then:         source ~/.bashrc"
  echo "  Or continue:  source ~/.bashrc && crew install <package>"
  exit 0
fi

bash /tmp/install-fixed.sh

crew_fix_environment
. ~/.bashrc
