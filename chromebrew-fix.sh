#!/usr/bin/env bash
#
# Chromebrew helper: git SHA fix + tar symlink + fastfetch-style menu (Chrome OS ASCII).
#
# Intended use from a terminal (VT-2 / chronos):
#   curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
#
# Skip the menu and run the installer only:
#   CHROMEBREW_FIX_QUICK=1 curl -fsSL .../chromebrew-fix.sh | bash
#
# Do not run with `sh`. Do not run as root.
#
set -e

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "chromebrew-fix: use bash. Example: curl ... | bash" >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  echo "chromebrew-fix: do not run as root. Use chronos." >&2
  exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main"
CREW_PREFIX=/usr/local

# --- display (fastfetch-ish) ---
reset=$'\033[0m'
bold=$'\033[1m'
dim=$'\033[2m'
red=$'\033[31m'
green=$'\033[32m'
yellow=$'\033[33m'
cyan=$'\033[36m'
white=$'\033[37m'
br_blue=$'\033[94m'
br_cyan=$'\033[96m'
br_white=$'\033[97m'

chrome_logo() {
  echo -e "${br_blue}${bold}"
  cat <<'EOF'
              ██████
          ██████████████
        ████░░░░░░░░████
      ████░░░░░░░░░░░░████
     ███░░░░ o    o ░░░░███
     ██░░░░░░░░░░░░░░░░░░██
     ██░░░░ chromeos ░░░░██
     ███░░░░░░░░░░░░░░░░███
      ████░░░░░░░░░░░░████
        ████░░░░░░░░████
          ██████████████
              ██████
EOF
  echo -e "${reset}"
}

read_os_info() {
  OS_LINE="Chrome OS (see Settings → About)"
  if [[ -f /etc/lsb-release ]]; then
    # shellcheck disable=SC1091
    source /etc/lsb-release 2>/dev/null || true
    OS_LINE="${CHROMEOS_RELEASE_DESCRIPTION:-$OS_LINE}"
  fi
  HOST_LINE="$(hostname 2>/dev/null || echo '?')"
  ARCH_LINE="$(uname -m 2>/dev/null || echo '?')"
  USER_LINE="$(id -un 2>/dev/null || echo '?')"
}

kv() {
  printf '  %b%-12s%b %s\n' "${cyan}" "$1" "${reset}" "$2"
}

draw_panel() {
  read_os_info
  clear 2>/dev/null || true

  echo -e "${br_white}${bold}  ╭─ Chromebrew Fix ${dim}·${reset}${br_white}${bold} Chrome OS helper ${reset}"
  echo -e "${dim}  │${reset}"
  chrome_logo | while IFS= read -r line; do echo -e "  ${dim}│${reset} $line"; done
  echo -e "${dim}  │${reset}"
  echo -e "  ${green}${bold}●${reset} ${white}${bold}system${reset}"
  kv "os" "$OS_LINE"
  kv "host" "$HOST_LINE"
  kv "arch" "$ARCH_LINE"
  kv "user" "$USER_LINE"
  echo ""
  echo -e "  ${green}${bold}●${reset} ${white}${bold}crew${reset}"
  if [[ -x /usr/local/bin/crew ]]; then
    printf '  %b%-12s%b %byes%b\n' "${cyan}" "crew" "${reset}" "${green}" "${reset}"
  else
    printf '  %b%-12s%b %bnot yet%b\n' "${cyan}" "crew" "${reset}" "${yellow}" "${reset}"
  fi
  if [[ -x /usr/local/bin/ruby ]]; then
    kv "ruby" "$(/usr/local/bin/ruby -v 2>/dev/null | head -1 || echo '?')"
  else
    kv "ruby" "—"
  fi
  echo ""
  echo -e "${dim}  ╰────────────────────────────────────────────${reset}"
  echo ""
}

ruby_tips() {
  clear 2>/dev/null || true
  echo -e "${bold}${br_cyan}Ruby errors: require_gem.rb / Kernel#require_relative${reset}"
  echo ""
  echo "The crew command loads gems (highline, json, ptools, …). If Ruby can’t load"
  echo "them, you’ll see errors pointing at require_gem.rb or require_relative."
  echo ""
  echo -e "${green}Fix order:${reset}"
  echo "  1)  source ~/.bashrc"
  echo "      (Chromebrew adds GEM_HOME / PATH here.)"
  echo "  2)  Optional: source /usr/local/etc/env.d/profile 2>/dev/null"
  echo "  3)  hash -r && which ruby gem crew"
  echo "  4)  gem env"
  echo "  5)  sudo chown -R \"\$(id -un)\":\"\$(id -gn)\" /usr/local"
  echo "  6)  If gems are missing but Ruby works:"
  echo "        /usr/local/bin/gem install highline ptools json --no-document"
  echo "      (Versions must match Chromebrew; clean reinstall is safer.)"
  echo "  7)  Worst case: let Chromebrew installer clear /usr/local and run"
  echo "      this script again (menu → install) for a full bootstrap."
  echo ""
  echo -e "${dim}Enter to return.${reset}"
  read -r _ </dev/tty || true
}

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

run_patch_git_only() {
  echo -e "${cyan}Fetching patch-git-only.sh …${reset}" >&2
  local tmp="/tmp/patch-git-only.$$"
  curl -fsSL "$REPO_RAW/patch-git-only.sh" -o "$tmp"
  bash "$tmp"
  rm -f "$tmp"
}

run_full_install() {
  echo "chromebrew-fix: starting install …" >&2
  cd "${HOME}" || cd /

  export PATH="/usr/bin:/bin:${PATH}"

  build_install_fixed

  echo "chromebrew-fix: running Chromebrew install.sh (answer prompts on keyboard) …" >&2
  bash /tmp/install-fixed.sh </dev/tty

  crew_fix_environment

  if [[ -f "${HOME}/.bashrc" ]]; then
    set +e
    # shellcheck disable=SC1090
    . "${HOME}/.bashrc"
    set -e
  fi

  echo "chromebrew-fix: finished. If crew is missing:  source ~/.bashrc  or open a new shell." >&2
}

show_main_menu() {
  while true; do
    draw_panel
    echo -e "  ${bold}${white}Menu${reset}  ${dim}(curl … | bash)${reset}"
    echo ""
    echo "    1)  Run Chromebrew install (patched git + tar fixes after)"
    echo "    2)  Patch git checksum only"
    echo "    3)  Help: Ruby require_gem / require_relative errors"
    echo "    4)  Exit"
    echo ""
    echo -ne "  ${cyan}Choice [1-4]:${reset} "
    read -r choice </dev/tty || choice=4
    case "$choice" in
      1)
        run_full_install
        echo -e "${dim}Enter for menu.${reset}"
        read -r _ </dev/tty || true
        ;;
      2)
        run_patch_git_only
        echo -e "${dim}Enter for menu.${reset}"
        read -r _ </dev/tty || true
        ;;
      3)
        ruby_tips
        ;;
      4|q|Q|'')
        echo "Bye."
        exit 0
        ;;
      *)
        echo -e "${red}  Invalid.${reset}"
        sleep 1
        ;;
    esac
  done
}

if [[ "${CHROMEBREW_FIX_QUICK:-}" == "1" ]]; then
  run_full_install
else
  show_main_menu
fi
