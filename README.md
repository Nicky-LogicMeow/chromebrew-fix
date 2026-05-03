# chromebrew-fix

## Run it (terminal — **curl**)

On your Chromebook (**VT-2**, user **chronos**, **bash** — not `sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
```

You get a **Chrome OS ASCII logo**, a **fastfetch-style** info block, and a **menu**:

1. **Chromebrew install** — patched `git` checksum + Chromebrew’s own prompts + tar fixes after  
2. **Patch git only** — helper for a failed “verify git” step  
3. **Ruby help** — `require_gem` / `require_relative` tips  
4. **Exit**

Menus read from **`/dev/tty`**, so this works even when the script is piped from **`curl`**.

**Installer only** (no menu), for scripting:

```bash
CHROMEBREW_FIX_QUICK=1 curl -fsSL https://raw.githubusercontent.com/Nicky-LogicMeow/chromebrew-fix/main/chromebrew-fix.sh | bash
```

**Legacy:** `chromebrew-menu.sh` is a one-liner that runs the same `curl | bash` as above.

---

## What it fixes

When you install [Chromebrew](https://github.com/chromebrew/chromebrew), the installer can stop on **git** checksum verification (wrong hash in `packages/git.rb` vs GitLab). This repo patches that during bootstrap.

---

## What the installer path does

- Injects the **git** SHA fix into Chromebrew’s `install.sh` before bootstrap downloads **git**.
- Runs Chromebrew with **`</dev/tty`** so **clear `/usr/local`** questions work when using **`curl | bash`**.
- After install: **`/usr/local`** ownership + **`/usr/local/bin/tar`** → system tar, **`PATH`** prefers **`/usr/bin`:/bin**.

**`patch-git-only.sh`** is still used internally when you pick **menu option 2** (or you can curl that file alone).

---

## After install

```bash
source ~/.bashrc
```

---

## Ruby errors (`require_gem.rb`, `Kernel#require_relative`)

`crew` needs Ruby gems (highline, json, ptools, …). Traces mentioning **`require_gem.rb`** usually mean **bad `GEM_HOME` / `PATH`** or a **half-installed `/usr/local`**.

1. **`source ~/.bashrc`**  
2. **`hash -r`**, **`which ruby`**, **`gem env`**, **`which crew`**  
3. **`sudo chown -R "$(id -un)":"$(id -gn)" /usr/local`**  
4. Prefer a **clean Chromebrew reinstall** over random **`gem install`** if versions don’t match.  
5. **Menu → option 3** prints the same hints on the device.

When Chromebrew fixes the upstream `git` binary hash, you can use their normal installer and skip this repo.
