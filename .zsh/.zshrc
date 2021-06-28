# --------------------------
# typeset
# --------------------------
. ${ZDOTDIR:-$HOME}/functions/typeset.sh

# --------------------------
# Load .zshrc files
# --------------------------
. ${ZDOTDIR:-$HOME}/functions/_sources.sh
_sources ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh(N-.)
