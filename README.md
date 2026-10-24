# neuromarchy

Personal Omarchy overlay for **prol** (MacBook Pro 14" M3 Pro, `apple,t6030` / `apple,j514s`).

[neuronix](https://github.com/timkoval/neuronix) stays the Nix flake (`elitebook`, `ai`, Darwin). This repo is the Arch/Omarchy side: packages + user configs + a few `/etc` drop-ins. Omarchy has no machine profile; `./bootstrap.sh` is that profile.

Captured from the 2026-10-24 session on Omarchy 4.0.3rc4 (omarchy-mac). Notes: [docs/omarchy-session-2026-10-24.md](docs/omarchy-session-2026-10-24.md).

## Apply on a new Omarchy install

1. Finish first boot (`omarchy finalize user` already ran).
2. Clone this repo (SSH once you have a GitHub key, or HTTPS then switch):

   ```bash
   git clone git@github.com:timkoval/neuromarchy.git ~/git-local/neuromarchy
   cd ~/git-local/neuromarchy
   ./bootstrap.sh
   ```

3. Sudo will prompt in this terminal. Use the **session** password, Dvorak. Physical Esc is Caps Lock after keyd starts; both Shifts cancel Caps.

4. After it finishes:

   ```bash
   sudo tailscale up --accept-routes
   sudo tailscale set --operator="$USER"
   ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f ~/.ssh/id_ed25519   # if no key yet
   gh auth login   # GitHub SSH
   gh auth setup-git
   ```

5. Open a **new** Super+Return window. Kitty starts Fish. Login shell stays bash (same as elitebook).

6. Logout once so the SDDM greeter picks up Dvorak.

Partial runs:

```bash
./bootstrap.sh --packages-only
./bootstrap.sh --home-only
./bootstrap.sh --system-only
```

## What it installs

**Packages** (`packages/pacman.txt`, `extra/` only, no AUR): direnv, atuin, just, yazi, pgcli, keyd, tailscale, yq, hyperfine, duf, dust, gdu, ast-grep, sad, doggo, gping, kitty, fish, bash-preexec, lsof, strace, firefox, tmux.

**Omarchy catalog:** Kitty as default terminal, Firefox beside Vivaldi, Tailscale bar plugin + receive service.

**Home overlay:** Hypr scrolling + 3-finger `scroll_move`, Fish vi + aliases, Kitty `shell fish --login`, tmux Fish + C-s prefix, git identity, fcitx Dvorak, bashrc that sources Omarchy rc and guards cargo env, SSH config for github.com and `ai`.

**System overlay:** keyd (Caps tap Esc / hold Ctrl, UK ISO extra keys), `hid_apple iso_layout=1`, SDDM greeter reads `/etc/vconsole.conf`.

Tmux plugins clone into `~/.config/tmux/plugins/` (navigator, resurrect, continuum).

## What it does not copy

- SSH private keys
- 1Password vault
- Vivaldi profile (the `.conf` flags and copy-url host are included; the browser package is not in `extra/` on aarch64 — rebuild from the Arch PKGBUILD if needed)
- `/etc/vconsole.conf` unless missing (this tree’s copy is us + dvorak)

## ANSI vs UK ISO

This Mac is UK ISO. `overlay/etc/keyd/default.conf` remaps the extra key, grave, and backslash. On an ANSI board, delete the `102nd` / `grave` / `backslash` lines after bootstrap, and skip or empty `hid-apple.conf`.

## After apply (manual)

| Task | Why |
|---|---|
| `tailscale up` | `ssh ai` and Moonlight. `ai` is `100.67.153.109`; authorize this host’s pubkey on `ai`. |
| `xdg-settings set default-web-browser vivaldi-stable.desktop` | Only if Vivaldi is installed. |
| Touch ID / panel brightness | Kernel: no `t6030` SEP profile, no `apple-panel-bl`. Wait for omacom aurora. |

## Optional later

git-delta, git-lfs, git-trim, glow, croc, easyeffects, cava, Emacs, Zed, Zellij, `playerctl`, Russian layout, docker group. See the session doc.

## Relation to Omarchy

Edit only `~/.config/` and the `/etc` drop-ins in this overlay. Never `/usr/share/omarchy/`. Theme/font stay Omarchy (Tokyo Night, JetBrainsMono). `omarchy refresh` will overwrite user files it owns; re-run `./bootstrap.sh --home-only` after that if needed.

A `post-boot` hook can run bootstrap, but do not enable it until the script is idempotent on your machine (it already skips identical files).

## Layout

```
bootstrap.sh
packages/pacman.txt
packages/omarchy-installs.txt
overlay/home/          → $HOME
overlay/etc/           → /etc
docs/
```
