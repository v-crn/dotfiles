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
# Load .zshenv files
# --------------------------
. ${ZDOTDIR:-$HOME}/functions/_sources.sh
. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_sources $ZDOTDIR/zshenv.zsh(N-.)
_sources ${ZDOTDIR:-$HOME}/.zshenv.d/*.zsh(N-.)
