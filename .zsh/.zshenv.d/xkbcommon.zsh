DEFAULT_XKB_DIR=/usr/share/X11/xkb
if [ -e "$DEFAULT_XKB_DIR" ]; then
    export XKB_CONFIG_ROOT="$DEFAULT_XKB_DIR"
fi
