#!/usr/bin/env bash
# Apply neuromarchy on an Omarchy machine. See README.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

DO_PACKAGES=1
DO_OMARCHY=1
DO_HOME=1
DO_SYSTEM=1
DO_TMUX_PLUGINS=1

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

  --packages-only     pacman packages via omarchy pkg add
  --home-only         user overlay (~/.config, shells, ssh config)
  --system-only       /etc keyd, hid-apple, SDDM greeter keymap
  --skip-packages
  --skip-omarchy      skip omarchy install terminal/browser/plugin
  --skip-home
  --skip-system
  --skip-tmux-plugins
  -h, --help
EOF
}

while (($#)); do
  case "$1" in
    --packages-only) DO_PACKAGES=1; DO_OMARCHY=0; DO_HOME=0; DO_SYSTEM=0; DO_TMUX_PLUGINS=0 ;;
    --home-only) DO_PACKAGES=0; DO_OMARCHY=0; DO_HOME=1; DO_SYSTEM=0; DO_TMUX_PLUGINS=1 ;;
    --system-only) DO_PACKAGES=0; DO_OMARCHY=0; DO_HOME=0; DO_SYSTEM=1; DO_TMUX_PLUGINS=0 ;;
    --skip-packages) DO_PACKAGES=0 ;;
    --skip-omarchy) DO_OMARCHY=0 ;;
    --skip-home) DO_HOME=0 ;;
    --skip-system) DO_SYSTEM=0 ;;
    --skip-tmux-plugins) DO_TMUX_PLUGINS=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if ! command -v omarchy >/dev/null; then
  echo "omarchy is not on PATH. Run this on an Omarchy install." >&2
  exit 1
fi

step_packages() {
  echo "==> packages (extra/, no AUR)"
  mapfile -t pkgs < <(read_pkg_list "$ROOT/packages/pacman.txt")
  omarchy pkg add "${pkgs[@]}"
}

step_omarchy() {
  echo "==> omarchy catalog"
  while read -r line; do
    [[ -z $line || $line == \#* ]] && continue
    # shellcheck disable=SC2086
    omarchy $line
  done <"$ROOT/packages/omarchy-installs.txt"

  systemctl --user enable --now omarchy-tailscale-receive.service 2>/dev/null || true
  sudo systemctl enable --now tailscaled.service
  echo "Tailscale daemon is on. Login later: sudo tailscale up --accept-routes && sudo tailscale set --operator=\$USER"
}

step_home() {
  echo "==> home overlay"
  local src dest rel

  # fcitx flushes the old profile on exit. Stop it before copying.
  systemctl --user stop omarchy-fcitx5.service 2>/dev/null || true

  while IFS= read -r -d '' src; do
    rel=${src#"$ROOT/overlay/home/"}
    dest="$HOME/$rel"
    install_file "$src" "$dest"
  done < <(find "$ROOT/overlay/home" -type f -print0)

  [[ -f $HOME/.ssh/config ]] && chmod 600 "$HOME/.ssh/config"
  systemctl --user enable --now ssh-agent.socket
  systemctl --user start omarchy-fcitx5.service 2>/dev/null || true

  if [[ ! -f $HOME/.ssh/id_ed25519 ]]; then
    echo "No ~/.ssh/id_ed25519. Generate one:"
    echo "  ssh-keygen -t ed25519 -C \"\$USER@\$(hostname)\" -f ~/.ssh/id_ed25519"
  fi
}

step_system() {
  echo "==> system overlay (sudo)"
  sudo install -d -m 755 /etc/keyd /etc/modprobe.d /etc/sddm /etc/sddm.conf.d
  sudo install -m 644 "$ROOT/overlay/etc/keyd/default.conf" /etc/keyd/default.conf
  sudo install -m 644 "$ROOT/overlay/etc/modprobe.d/hid-apple.conf" /etc/modprobe.d/hid-apple.conf
  sudo install -m 644 "$ROOT/overlay/etc/sddm/greeter-hyprland.lua" /etc/sddm/greeter-hyprland.lua
  sudo install -m 644 "$ROOT/overlay/etc/sddm.conf.d/50-keymap.conf" /etc/sddm.conf.d/50-keymap.conf

  if [[ -f /etc/vconsole.conf ]]; then
    echo "Leaving /etc/vconsole.conf in place (current KEYMAP/XKBLAYOUT)."
    echo "This host's copy is overlay/etc/vconsole.conf (us dvorak)."
  else
    sudo install -m 644 "$ROOT/overlay/etc/vconsole.conf" /etc/vconsole.conf
  fi

  if [[ -w /sys/module/hid_apple/parameters/iso_layout ]]; then
    echo 1 | sudo tee /sys/module/hid_apple/parameters/iso_layout >/dev/null
  fi

  sudo systemctl enable --now keyd.service
  sudo keyd reload || sudo systemctl restart keyd.service
}

step_tmux_plugins() {
  echo "==> tmux plugins"
  mkdir -p "$HOME/.config/tmux/plugins"
  clone_plugin() {
    local name=$1 url=$2
    local dir="$HOME/.config/tmux/plugins/$name"
    if [[ -d $dir/.git ]]; then
      git -C "$dir" pull --ff-only || true
    else
      git clone --depth 1 "$url" "$dir"
    fi
  }
  clone_plugin vim-tmux-navigator https://github.com/christoomey/vim-tmux-navigator.git
  clone_plugin tmux-resurrect https://github.com/tmux-plugins/tmux-resurrect.git
  clone_plugin tmux-continuum https://github.com/tmux-plugins/tmux-continuum.git
}

[[ $DO_PACKAGES == 1 ]] && step_packages
[[ $DO_OMARCHY == 1 ]] && step_omarchy
[[ $DO_HOME == 1 ]] && step_home
[[ $DO_SYSTEM == 1 ]] && step_system
[[ $DO_TMUX_PLUGINS == 1 ]] && step_tmux_plugins

echo
echo "neuromarchy applied."
echo "Next:"
echo "  1. New terminal (Kitty + Fish). Login shell stays bash."
echo "  2. sudo tailscale up --accept-routes && sudo tailscale set --operator=\$USER"
echo "  3. gh auth login  (SSH) and gh auth setup-git"
echo "  4. Vivaldi is not in extra/; see README if you need it again."
echo "  5. ANSI keyboard: drop the 102nd/grave/backslash lines from /etc/keyd/default.conf"
