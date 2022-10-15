if [ -e "/usr/lib/wsl/lib" ]; then
    export PATH="/usr/lib/wsl/lib:$PATH"
fi

if [ -e "/usr/local/cuda/lib64" ]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
fi
