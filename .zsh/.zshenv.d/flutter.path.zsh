if [-e "$HOME/fvm/default/bin"]; then
    export PATH="$PATH":"$HOME/fvm/default/bin"
elif [-e "$HOME/flutter/bin"]; then
    export PATH="$PATH":"$HOME/flutter/bin"
fi
