#!/bin/sh
# Run once: restrict ~/.config/zsh permissions to owner-only
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
chmod 700 "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
