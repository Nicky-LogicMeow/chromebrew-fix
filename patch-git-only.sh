#!/bin/bash
# If Chromebrew install already failed at "Verifying git", run this, then re-run
# chromebrew-fix.sh or the official installer (you may need to clear /usr/local when asked).
set -e
sudo sed -i 's/68ae392e60447d052a8acb171542bcd69161157b97e58f07941d476f7f6ccfc2/15e896483bc5f96cba44ad192a89788cff29ec0372b94b73f176e82857b4abb7/' /usr/local/lib/crew/packages/git.rb
sudo rm -f /usr/local/tmp/crew/git-2.54.0-chromeos-x86_64.tar.zst
echo "Patched git.rb and removed bad tarball. Continue with Chromebrew install as needed."
