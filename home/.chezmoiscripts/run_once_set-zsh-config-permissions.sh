#!/bin/sh
# Run once: restrict ~/.config/zsh permissions to owner-only
chmod 700 "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
