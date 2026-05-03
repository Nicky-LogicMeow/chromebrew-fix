#!/bin/bash
# If Chromebrew install already failed at "Verifying git", run this, then re-run chromebrew-fix.sh
# or the official installer (answer the /usr/local prompt if asked).
set -e

CREW_PREFIX=/usr/local

sudo sed -i 's/68ae392e60447d052a8acb171542bcd69161157b97e58f07941d476f7f6ccfc2/15e896483bc5f96cba44ad192a89788cff29ec0372b94b73f176e82857b4abb7/' "$CREW_PREFIX/lib/crew/packages/git.rb"
sudo rm -f "$CREW_PREFIX/tmp/crew/git-2.54.0-chromeos-x86_64.tar.zst"

sudo chown -R "$(id -u)":"$(id -g)" "$CREW_PREFIX" 2>/dev/null || true

sys_tar=""
for candidate in /usr/bin/tar /bin/tar; do
  [[ -x "$candidate" ]] && sys_tar="$candidate" && break
done
if [[ -n "$sys_tar" ]]; then
  sudo mkdir -p "$CREW_PREFIX/bin"
  sudo rm -f "$CREW_PREFIX/bin/tar"
  sudo ln -sf "$sys_tar" "$CREW_PREFIX/bin/tar"
fi

export PATH="/usr/bin:/bin:${PATH}"

echo "Patched git.rb, removed bad tarball, fixed /usr/local ownership and tar symlink."
echo "Run chromebrew-fix.sh or the Chromebrew installer again."
