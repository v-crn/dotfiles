if [ -e "/usr/local/cuda/bin" ]; then
    export PATH="/usr/local/cuda/bin:$PATH"
fi

if [ -e "/usr/local/cuda/lib64" ]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
fi
