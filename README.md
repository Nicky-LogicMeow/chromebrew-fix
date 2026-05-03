# Chromebrew git checksum workaround

Chromebrew’s `packages/git.rb` for **git 2.54.0** on **x86_64** may list a SHA256 that does not match the file on GitLab, so install fails at **Verifying git**.

This repo hosts a small installer wrapper that patches `git.rb` right after the Chromebrew tree is unpacked.

## Chromebook (VT-2, `chronos`)

If you cannot paste into the shell, save `chromebrew-fix.sh` to **Downloads** from GitHub (Raw), then:

```bash
bash /home/chronos/user/Downloads/chromebrew-fix.sh
```

(Adjust the path if your Downloads folder differs; use `ls /home/chronos/user/Downloads`.)

Or clone this repo on another machine, copy the script to the Chromebook, and run it.

## Scripts

- **`chromebrew-fix.sh`** — full install with the checksum patch applied.
- **`patch-git-only.sh`** — patch an in-progress `/usr/local` after a failed git step (then re-run install / follow Chromebrew prompts).

## Upstream

When [chromebrew/chromebrew](https://github.com/chromebrew/chromebrew) updates `binary_sha256` for git x86_64, you can use the official installer again and this workaround may be unnecessary.

## Publish this folder to your GitHub

1. On GitHub (logged in): **New repository** → name it (e.g. `chromebrew-git-sha-fix`) → create **without** adding a README (avoid merge conflicts).
2. On your PC, in this folder:

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

Use a [personal access token](https://github.com/settings/tokens) as the password if Git asks for credentials, or set up SSH.

**Raw script URL** (after push), for easy download on a Chromebook:

`https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/chromebrew-fix.sh`
