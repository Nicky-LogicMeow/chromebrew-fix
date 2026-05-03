#!/usr/bin/env bash
# Fastfetch-style launcher for chromebrew-fix (Chrome OS ASCII + menu).
# Run: bash chromebrew-menu.sh
set -e

[[ -n "${BASH_VERSION:-}" ]] || { echo "Use: bash $0" >&2; exit 1; }

REPO_RAW="https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

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
  echo "      chromebrew-fix again for a full bootstrap."
  echo ""
  echo -e "${dim}Enter to return.${reset}"
  read -r _ </dev/tty || true
}

run_chromebrew_fix() {
  if [[ -f "$SCRIPT_DIR/chromebrew-fix.sh" ]]; then
    bash "$SCRIPT_DIR/chromebrew-fix.sh" </dev/tty
  else
    echo -e "${cyan}Downloading chromebrew-fix.sh …${reset}"
    curl -fsSL "$REPO_RAW/chromebrew-fix.sh" -o /tmp/chromebrew-fix.sh
    bash /tmp/chromebrew-fix.sh </dev/tty
  fi
}

run_patch_git_only() {
  if [[ -f "$SCRIPT_DIR/patch-git-only.sh" ]]; then
    bash "$SCRIPT_DIR/patch-git-only.sh"
  else
    curl -fsSL "$REPO_RAW/patch-git-only.sh" -o /tmp/patch-git-only.sh
    bash /tmp/patch-git-only.sh
  fi
}

main_menu() {
  while true; do
    draw_panel
    echo -e "  ${bold}${white}Menu${reset}"
    echo ""
    echo "    1)  Run Chromebrew install (chromebrew-fix)"
    echo "    2)  Patch git checksum only"
    echo "    3)  Help: Ruby require_gem / require_relative errors"
    echo "    4)  Exit"
    echo ""
    echo -ne "  ${cyan}Choice [1-4]:${reset} "
    read -r choice </dev/tty || choice=4
    case "$choice" in
      1)
        run_chromebrew_fix
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

main_menu
