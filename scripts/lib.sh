# shellcheck shell=bash

neuromarchy_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

backup_file() {
  local dest=$1
  if [[ -e $dest && ! -L $dest ]]; then
    cp -a "$dest" "${dest}.bak.$(date +%s)"
  fi
}

install_file() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [[ -e $dest ]] && cmp -s "$src" "$dest"; then
    return 0
  fi
  backup_file "$dest"
  install -m 644 "$src" "$dest"
}

read_pkg_list() {
  local file=$1
  awk 'NF && $1 !~ /^#/' "$file"
}
