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
. ${ZDOTDIR:-$HOME}/.functions.d/_sources.sh

_sources ${ZDOTDIR:-$HOME}/.zshenv.d/*.zsh(N-.)
