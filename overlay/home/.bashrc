# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# If not running interactively, don't do anything else
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
source "$OMARCHY_PATH/default/bash/rc"

if command -v direnv >/dev/null; then
  eval "$(direnv hook bash)"
fi

if command -v atuin >/dev/null; then
  eval "$(atuin init bash)"
fi
