# chromebrew-fix

## What it fixes

When you install [Chromebrew](https://github.com/chromebrew/chromebrew) on a Chromebook, the installer can stop and say **git** failed verification (wrong checksum), even though the download is fine. This happens because the expected hash in Chromebrew’s config didn’t match the real **git** package file for some Chromebooks.

These scripts fix that mismatch so the install can continue.

## What it does

**`chromebrew-fix.sh`** runs Chromebrew’s normal installer but applies a small fix to the config **before** it tries to download **git**, so verification succeeds.

**`patch-git-only.sh`** is only if you already hit the error once: it fixes the same config line and removes the bad cached file. After that, run the installer again (or use `chromebrew-fix.sh` from a clean setup).

## How to use it

**Easiest:** on your Chromebook, in the Linux-style shell you use for Chromebrew, paste or type:

```bash
curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
```

When it finishes, run:

```bash
source ~/.bashrc
```

**If paste doesn’t work in that shell:** open the link above in the browser, save the file as `chromebrew-fix.sh`, then run:

```bash
bash ~/Downloads/chromebrew-fix.sh
```

(If `Downloads` isn’t there, move the file to your home folder and run `bash chromebrew-fix.sh` from that folder.)

When Chromebrew itself is fixed upstream, you can use their normal install command again and you won’t need this repo.
