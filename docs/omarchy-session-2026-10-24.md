# Omarchy session notes — 2026-10-24

Host: **prol** (user `tkoval`)
Machine: MacBook Pro 14-inch M3 Pro (Mac15,6, `apple,t6030` / `apple,j514s`)
OS: Omarchy 4.0.3rc4-1 (omarchy-mac), Hyprland 0.56.2, aurora kernel `7.1.12-2-20261017.20-sep-ARCH`

This is a log of what we changed or decided in this session. Kernel-blocked items were left as-is.

---

## 1. Touch ID — no change (kernel)

Touch ID cannot be used on this SoC yet.

- `aurora-touchid` is already installed; `apple-sep.service` is enabled.
- `apple_sep` logs: no platform profile for this SoC; the SEP stays disabled.
- `/dev/sep-bio` is missing; `fprintd` sees no devices.
- Do **not** run `omarchy setup security fingerprint` (USB readers only).
- When `/dev/sep-bio` exists: `aurora-touchid-setup`.

Wait for a kernel that registers a `t6030` SEP profile.

## 2. Display brightness — no change (kernel)

The panel stays at firmware brightness.

- `/sys/class/backlight` is empty; no `apple-panel-bl`.
- DCP: `Could not find Backlight service`.
- Brightness keys already call `omarchy brightness display`; they will work once the node appears.
- Keyboard backlight (`white:kbd_backlight`) already works with Shift+brightness.

Wait for a kernel that registers the panel backlight.

## 3. Session lock typed QWERTY on Dvorak

**Cause:** Hyprland is `us` + `dvorak` from `/etc/vconsole.conf`. The lock screen (and polkit) are Qt `TextInput` with `QT_IM_MODULE=fcitx`. fcitx’s stock profile was `keyboard-us` (QWERTY).

**Change:** Stopped `omarchy-fcitx5`, rewrote `~/.config/fcitx5/profile` from vconsole (`keyboard-us-dvorak`), started fcitx again.

```
Default Layout=us-dvorak
DefaultIM=keyboard-us-dvorak
Name=keyboard-us-dvorak
```

Upstream already merged this as omacom/omarchy#14433 on `quattro`; this 4.0.3rc4 package does not have it. No extra PR.

Do not edit the profile while fcitx is running (it flushes the old profile on exit).

## 4. Login screen (SDDM) typed QWERTY

**Cause:** No autologin. The startup “lock” is the SDDM greeter. It runs its own Hyprland from `/usr/share/sddm/hyprland.lua` with no `kb_layout`, so Hyprland defaults to US QWERTY. fcitx is not in the greeter.

**Change (needs sudo, already installed):**

- `/etc/sddm/greeter-hyprland.lua` — reads `XKBLAYOUT` / `XKBVARIANT` from `/etc/vconsole.conf` (same source as the session).
- `/etc/sddm.conf.d/50-keymap.conf` — points `CompositorCommand` at that file.

Logout or reboot to use it. Package updates that rewrite `/usr/share/sddm/hyprland.lua` do not undo this drop-in.

## 5. Niri-like scrolling layout

**Change:**

- `~/.config/hypr/looknfeel.lua` — default layout `scrolling`, `column_width = 0.97`, `fullscreen_on_one_column = true`, `focus_fit_method = 0` (center).
- `~/.config/hypr/input.lua` — 3-finger horizontal swipe = `scroll_move`.

Still in place: software cursor (`no_hardware_cursors = true`), Caps/Escape swap.

**Use:** Super+Left/Right move columns; Super+L toggles this workspace back to dwindle. Hyprland 0.56 has no niri-style overview.

## 6. Vivaldi

Not in Omarchy’s `omarchy install browser` list and not in the aarch64 repos.

**Change:** Built the official Arch PKGBUILD from the aarch64 RPM, then `pacman -U`.

- Package: `vivaldi 8.2.4133.94-1`
- Binaries: `/usr/bin/vivaldi`, `/usr/bin/vivaldi-stable`
- Flags: `~/.config/vivaldi-stable.conf` (copy of Omarchy chromium-flags: Wayland, libsecret, copy-url / yt-dlp / whatsapp-slim extensions)
- Native host: `~/.config/vivaldi/NativeMessagingHosts/com.omarchy.copy_url.json`
- Build leftover: `~/.cache/omarchy-vivaldi-build/`

Chromium is still the default browser. To switch:

```bash
xdg-settings set default-web-browser vivaldi-stable.desktop
```

## 7. GitHub SSH

**Change:**

- Key: `~/.ssh/id_ed25519` (comment `tkoval@prol`, **no passphrase**)
- `~/.ssh/config` — `Host github.com` uses that key, `IdentitiesOnly yes`, `AddKeysToAgent yes`
- `github.com` in `~/.ssh/known_hosts`
- `systemctl --user enable --now ssh-agent.socket`
- `~/.config/environment.d/ssh-agent.conf` — `SSH_AUTH_SOCK=${XDG_RUNTIME_DIR}/ssh-agent.socket`
- `gh` logged in as **timkoval**, git protocol SSH
- Key on GitHub as `prol-20261024`

Verified: `ssh -T git@github.com` → `Hi timkoval!`

Clone with `git@github.com:USER/REPO.git`. Add a passphrase later with:

```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
```

## 8. Login bounced back to the greeter

**Cause:** UWSM’s env-preloader sources `~/.profile` with `set -e`. rustup had added `. "$HOME/.cargo/env"` but `~/.cargo/env` does not exist, so the preloader exited 1 and SDDM restarted the greeter. Auth itself succeeded (`gkr-pam: couldn't unlock the login keyring` is a separate warning).

**Change:** Guarded the cargo source in:

- `~/.profile`
- `~/.bash_profile`
- `~/.bashrc`

```sh
if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
```

Use `if`, not `&&`. A failing `[ -f ]` as the last command of a sourced file still aborts under `set -e`.

## 9. Later the same day (neuronix elitebook + tooling)

- Git user `Tim Koval` / `timkoval00@gmail.com` and extra aliases.
- CLI: direnv, atuin, just, yazi, pgcli, yq, hyperfine, duf, dust, gdu, ast-grep, sad, doggo, gping, lsof, strace.
- Kitty default terminal; Fish in Kitty (`shell fish --login`) with vi cursors and Omarchy/elitebook aliases. Login shell remains bash.
- Tmux: Fish default-shell, prefix C-s, wl-copy, resurrect/continuum.
- keyd: Caps tap Esc / hold Ctrl; UK ISO 102nd/grave/backslash; `hid_apple iso_layout=1`.
- Tailscale up (host **prol** `100.103.140.127`). `Host ai` in SSH config. `ai` was offline on the tailnet.
- Firefox + Omarchy `policies.json`; Vivaldi is default browser.
- Restored Omarchy `~/.bashrc` sourcing (`starship` / `zoxide` / `mise`) after the cargo/`set -e` fix.

These files live in this repo’s `overlay/` and are applied by `./bootstrap.sh`.

## 10. Neovim (LazyVim + neuronvim habits)

Keep Omarchy LazyVim and snacks. Overlay only:

- `lua/plugins/oil.lua` — `-` and `<leader>-`
- `lua/plugins/tmux-navigator.lua` — `C-h/j/k/l`
- `lua/plugins/rust.lua` — rustaceanvim `excludeDirs` for `.direnv` and `target`
- `lazyvim.json` extra `lang.rust` (crates.nvim included)
- `lua/config/keymaps.lua` — `<leader>sf` snacks files, `<leader>rn` rename

Do not replace `init.lua` / theme-hotreload.

---

## Files touched

| Path | What |
|------|------|
| `~/.config/fcitx5/profile` | Dvorak fcitx engine from vconsole |
| `/etc/sddm/greeter-hyprland.lua` | Greeter reads vconsole layout |
| `/etc/sddm.conf.d/50-keymap.conf` | Greeter uses that Hyprland config |
| `~/.config/hypr/looknfeel.lua` | Scrolling layout |
| `~/.config/hypr/input.lua` | 3-finger `scroll_move` |
| `~/.config/vivaldi-stable.conf` | Wayland/Chromium flags |
| `~/.config/vivaldi/NativeMessagingHosts/com.omarchy.copy_url.json` | Copy-URL host |
| `~/.ssh/id_ed25519`, `.pub`, `config`, `known_hosts` | GitHub SSH |
| `~/.config/environment.d/ssh-agent.conf` | Agent socket |
| `~/.config/systemd/user/sockets.target.wants/ssh-agent.socket` | Agent enabled |
| `~/.profile`, `~/.bash_profile`, `~/.bashrc` | Guard missing cargo env |

## Not changed (waiting on kernel)

Touch ID (`t6030` SEP) and panel backlight (`apple-panel-bl`).
