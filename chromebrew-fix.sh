#!/bin/bash
# Chromebrew installer wrapper: git 2.54.0 x86_64 SHA256 fix + common permission/tar fixes.
# See README.
set -e

CREW_PREFIX=/usr/local

if [[ "${EUID}" -eq 0 ]]; then
  echo "Do not run this script as root. Log in as chronos and try again."
  exit 1
fi

crew_fix_permissions() {
  [[ -d "$CREW_PREFIX" ]] || return 0
  sudo chown -R "$(id -u)":"$(id -g)" "$CREW_PREFIX" 2>/dev/null || true
  if [[ -e "$CREW_PREFIX/bin/tar" ]]; then
    chmod a+x "$CREW_PREFIX/bin/tar" 2>/dev/null || sudo chmod a+x "$CREW_PREFIX/bin/tar" 2>/dev/null || true
  fi
}

cd ~

if [[ -d "$CREW_PREFIX" ]] && [[ -n "$(ls -A "$CREW_PREFIX" 2>/dev/null)" ]]; then
  echo ""
  echo "$CREW_PREFIX is not empty. A broken or old Chromebrew install often needs a clean folder."
  # Read from the terminal so this still works when the script is piped: curl ... | bash
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

crew_fix_permissions

curl -fsSL https://raw.githubusercontent.com/chromebrew/chromebrew/master/install.sh -o /tmp/install.sh
awk '
/tar -xz --strip-components=1 -C/ {
  print
  print "sed -i \"s/68ae392e60447d052a8acb171542bcd69161157b97e58f07941d476f7f6ccfc2/15e896483bc5f96cba44ad192a89788cff29ec0372b94b73f176e82857b4abb7/\" \"${CREW_LIB_PATH}/packages/git.rb\""
  next
}
{ print }' /tmp/install.sh > /tmp/install-fixed.sh

bash /tmp/install-fixed.sh

crew_fix_permissions
. ~/.bashrc
