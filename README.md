# chromebrew-fix

## What it fixes

When you install [Chromebrew](https://github.com/chromebrew/chromebrew) on a Chromebook, the installer can stop and say **git** failed verification (wrong checksum), even though the download is fine. This happens because the expected hash in Chromebrew’s config didn’t match the real **git** package file for some Chromebooks.

These scripts fix that mismatch so the install can continue.

## What it does

**`chromebrew-fix.sh`** runs Chromebrew’s normal installer but:

- Patches the **git** checksum issue **before** bootstrap downloads **git**.
- If **`/usr/local` already has files**, it **asks** whether to **delete everything there** (recommended for a clean reinstall; default is **no** if you just press Enter).
- Makes **`/usr/local`** owned by your user, replaces **`/usr/local/bin/tar`** with a **symlink** to Chrome OS’s **`/usr/bin/tar`** or **`/bin/tar`** (so `crew`’s `system 'tar', …` is never a broken binary). Puts **`/usr/bin` and `/bin` first in `PATH`**. That targets **Permission denied – tar** when a package has **no precompiled binary** and unpacks source archives.

**`patch-git-only.sh`** is only if you already hit the **git verify** error once: it patches the same config line, removes the bad cached **git** archive, and applies the same **ownership / tar** fixes. Then run **`chromebrew-fix.sh`** or the installer again.

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

## Testing / continue where you left off

Environment variables (same line as `bash`, or `export` first):

| Variable | Effect |
|----------|--------|
| `CHROMEBREW_FIX_MODE=retry` | Do **not** ask about clearing `/usr/local`. Reuse **`/tmp/install-fixed.sh`** if it is already there (faster). Then run the installer again. |
| `CHROMEBREW_FIX_RESUME=1` | Same as **`MODE=retry`**. |
| `CHROMEBREW_FIX_MODE=prep` | Only apply fixes and build **`/tmp/install-fixed.sh`** if missing. **Does not** run the big install. Then you can run `bash /tmp/install-fixed.sh` or `source ~/.bashrc && crew install …` yourself. |

Examples:

```bash
CHROMEBREW_FIX_MODE=retry bash chromebrew-fix.sh
CHROMEBREW_FIX_MODE=prep bash chromebrew-fix.sh
```

When Chromebrew itself is fixed upstream, you can use their normal install command again and you won’t need this repo.
