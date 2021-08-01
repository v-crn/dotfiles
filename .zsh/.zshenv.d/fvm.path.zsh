# Linux
if [ -e "$HOME/fvm/default/bin" ]; then
    export PATH="$PATH":"$HOME/fvm/default/bin"
# macOS
elif [ -e "$HOME/.pub-cache/bin" ]; then
    export PATH="$PATH":"$HOME/.pub-cache/bin"
fi
