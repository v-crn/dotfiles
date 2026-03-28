if [ -e "/opt/homebrew/bin" ]; then
    # Consider setting your PATH so that /opt/homebrew/bin occurs before /usr/bin.
    export PATH="/opt/homebrew/bin:$PATH"
fi

if [ -e "/opt/homebrew/sbin" ]; then
    export PATH="/opt/homebrew/sbin:$PATH"
fi
