#
# Defines environment variables.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ("$SHLVL" -eq 1 && ! -o LOGIN) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# --------------------------
# Load .env
# 環境変数に無い.env変数を環境変数としてインポートする
# --------------------------
if [ -f "$HOME/dotfiles/.env" ]; then
    set -a
    eval "$(cat $HOME/dotfiles/.env <(echo) <(declare -x))"
    set +a
fi

# --------------------------
# Load .zshenv files
# --------------------------
. ${ZDOTDIR:-$HOME}/functions/_sources.sh
. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh
. ${ZDOTDIR:-$HOME}/functions/git_functions.sh

_sources $ZDOTDIR/.zshenv.zsh(N-.)
_sources ${ZDOTDIR:-$HOME}/.zshenv.d/*.zsh(N-.)
