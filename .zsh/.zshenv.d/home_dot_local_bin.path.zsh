target_path=$HOME/.local/bin
if [ -e $target_path ]; then
    export PATH="$PATH":"$target_path"
fi
