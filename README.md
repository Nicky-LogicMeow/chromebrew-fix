# chromebrew-fix

## What it fixes

When you install [Chromebrew](https://github.com/chromebrew/chromebrew) on a Chromebook, the installer can stop and say **git** failed verification (wrong checksum), even though the download is fine. This happens because the expected hash in Chromebrew’s config didn’t match the real **git** package file for some Chromebooks.

These scripts fix that mismatch so the install can continue.

## What it does

**`chromebrew-fix.sh`** runs Chromebrew’s normal installer but:

- Patches the **git** checksum issue **before** bootstrap downloads **git**.
- Lets **Chromebrew’s own** installer ask questions (for example whether to clear **`/usr/local`**). The script runs that installer with the keyboard connected to the real terminal (**`/dev/tty`**) so menus like **`select` do not exit immediately** when you used `curl … | bash`.
- After Chromebrew finishes, it fixes **`/usr/local`** ownership and adds a **`/usr/local/bin/tar`** symlink to Chrome OS’s **`/usr/bin/tar`** or **`/bin/tar`**, and keeps **`/usr/bin` and `/bin` first in `PATH`**.

**`patch-git-only.sh`** is only if you already hit the **git verify** error once: it patches the same config line, removes the bad cached **git** archive, and applies the same **ownership / tar** fixes. Then run **`chromebrew-fix.sh`** or the installer again.

## How to use it

On your Chromebook, in the shell you use for Chromebrew (**must be `bash`**, not `sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
```

When Chromebrew asks about **`/usr/local`**, use **1** / **2** or the keys it expects for **Yes** / **No** on the **`select`** menu.

If menus still act weird, download then run (same TTY fix is inside the script, but this is reliable):

```bash
curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh -o ~/chromebrew-fix.sh
bash ~/chromebrew-fix.sh
```

When it finishes, open a **new** shell or run:

```bash
source ~/.bashrc
```

Never run `sh chromebrew-fix.sh` — use **`bash`**.

When Chromebrew itself is fixed upstream, you can use their normal install command again and you won’t need this repo.
