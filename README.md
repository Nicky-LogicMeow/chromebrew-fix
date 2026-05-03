# chromebrew-fix

## What it fixes

When you install [Chromebrew](https://github.com/chromebrew/chromebrew) on a Chromebook, the installer can stop and say **git** failed verification (wrong checksum), even though the download is fine. This happens because the expected hash in Chromebrew’s config didn’t match the real **git** package file for some Chromebooks.

These scripts fix that mismatch so the install can continue.

## What it does

**`chromebrew-fix.sh`** runs Chromebrew’s normal installer but:

- Patches the **git** checksum issue **before** bootstrap downloads **git**.
- If **`/usr/local` already has files**, it **asks** whether to **delete everything inside it** (recommended for a clean reinstall; default is **no** if you just press Enter). It removes each top-level item with **`rm -rf`** so nested trees and hidden names actually go away (not only `find -delete`, which can miss edge cases).
- After Chromebrew’s installer finishes, it makes **`/usr/local`** owned by your user and adds a **`/usr/local/bin/tar`** **symlink** to Chrome OS’s **`/usr/bin/tar`** or **`/bin/tar`**, and uses **`/usr/bin` and `/bin` first in `PATH`**. (It does **not** create anything under **`/usr/local`** *before* the installer: Chromebrew requires **`/usr/local`** to be **empty** at the start, or it will say it is not empty.)

**`patch-git-only.sh`** is only if you already hit the **git verify** error once: it patches the same config line, removes the bad cached **git** archive, and applies the same **ownership / tar** fixes. Then run **`chromebrew-fix.sh`** or the installer again.

## How to use it

**Easiest:** on your Chromebook, in the shell you use for Chromebrew (**must be `bash`**, not `sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
```

You should see lines like `chromebrew-fix: starting...` and `chromebrew-fix: running Chromebrew install.sh ...`. If you see nothing, the download failed or the script is not running with **bash**.

When it finishes, open a **new** shell or run:

```bash
source ~/.bashrc
```

**If paste doesn’t work in that shell:** save the raw script from the link above as `chromebrew-fix.sh`, then:

```bash
bash ~/Downloads/chromebrew-fix.sh
```

Never run `sh chromebrew-fix.sh` — use **`bash`**.

(If `Downloads` isn’t there, move the file to your home folder and run `bash chromebrew-fix.sh` from that folder.)

When Chromebrew itself is fixed upstream, you can use their normal install command again and you won’t need this repo.
