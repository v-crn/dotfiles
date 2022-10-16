target_path=$HOME/.config/hadolint.yaml

if [ -e $target_path ]; then
    export XDG_CONFIG_HOME=$target_path
fi
