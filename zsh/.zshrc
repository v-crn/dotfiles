#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# --------------------------
# Load .zshrc files
# --------------------------
. ${ZDOTDIR:-$HOME}/.functions.d/_sources.sh

_sources ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh(N-.)
