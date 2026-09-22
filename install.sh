#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAK="$HOME/.dotfiles.bak/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BAK"

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BAK$(dirname "$dst" | sed "s|$HOME||")"
    cp -a "$dst" "$BAK$(echo "$dst" | sed "s|$HOME||")" 2>/dev/null || cp -a "$dst" "$BAK/"
    echo "backup: $dst -> $BAK"
  fi
  ln -sfn "$src" "$dst"
  echo "link: $dst -> $src"
}

link_dir() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    cp -a "$dst" "$BAK/$(basename "$dst")" 2>/dev/null || true
    echo "backup: $dst -> $BAK/$(basename "$dst")"
    rm -rf "$dst"
  fi
  ln -sfn "$src" "$dst"
  echo "link: $dst -> $src"
}

# emacs (files + plugins)
for f in init.el cosmic-theme.el matugen-theme.el; do
  [ -f "$DOTFILES_DIR/emacs/$f" ] && link_file "$DOTFILES_DIR/emacs/$f" "$HOME/.config/emacs/$f"
done
# plugins: elpa/ is tracked (archives/*.signed/gnupg excluded). Symlink whole dir;
# init.el auto-installs missing packages on first run if dir is absent.
if [ -d "$DOTFILES_DIR/emacs/elpa" ]; then
  link_dir "$DOTFILES_DIR/emacs/elpa" "$HOME/.config/emacs/elpa"
fi

# shell
for f in .bashrc .bash_profile .profile .gitconfig; do
  [ -f "$DOTFILES_DIR/shell/$f" ] && link_file "$DOTFILES_DIR/shell/$f" "$HOME/$f"
done

# nvim (whole dir)
if [ -d "$DOTFILES_DIR/nvim" ]; then
  link_dir "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# btop
[ -f "$DOTFILES_DIR/btop/btop.conf" ] && link_file "$DOTFILES_DIR/btop/btop.conf" "$HOME/.config/btop/btop.conf"

# matugen (config + templates + scripts + themes, skip generated/)
if [ -d "$DOTFILES_DIR/matugen" ]; then
  mkdir -p "$HOME/.config/matugen/themes"
  link_file "$DOTFILES_DIR/matugen/config.toml" "$HOME/.config/matugen/config.toml"
  for d in templates scripts themes; do
    if [ -d "$DOTFILES_DIR/matugen/$d" ]; then
      mkdir -p "$HOME/.config/matugen/$d"
      for src in "$DOTFILES_DIR/matugen/$d"/*; do
        [ -e "$src" ] || continue
        base="$(basename "$src")"
        link_file "$src" "$HOME/.config/matugen/$d/$base"
      done
    fi
  done
fi

echo "Done. Backups (if any) in $BAK"
