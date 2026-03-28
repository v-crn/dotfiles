if [ -e "$HOME/fvm/default/bin" ]; then
    export PATH="$PATH":"$HOME/fvm/default/bin"
elif [ -e "$HOME/flutter/bin" ]; then
    export PATH="$PATH":"$HOME/flutter/bin"
elif [ -e "$HOME/snap/flutter/common/flutter/bin/flutter" ]; then
    export PATH="$PATH":"$HOME/snap/flutter/common/flutter/bin"
fi
