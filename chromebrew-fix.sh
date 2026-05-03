#!/bin/bash
# Chromebrew installer wrapper: fixes git 2.54.0 x86_64 binary_sha256 mismatch
# (GitLab artifact vs packages/git.rb on chromebrew master). See README.
set -e
curl -fsSL https://raw.githubusercontent.com/chromebrew/chromebrew/master/install.sh -o /tmp/install.sh
awk '
/tar -xz --strip-components=1 -C/ {
  print
  print "sed -i \"s/68ae392e60447d052a8acb171542bcd69161157b97e58f07941d476f7f6ccfc2/15e896483bc5f96cba44ad192a89788cff29ec0372b94b73f176e82857b4abb7/\" \"${CREW_LIB_PATH}/packages/git.rb\""
  next
}
{ print }' /tmp/install.sh > /tmp/install-fixed.sh
bash /tmp/install-fixed.sh
. ~/.bashrc
