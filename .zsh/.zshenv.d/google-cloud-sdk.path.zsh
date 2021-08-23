# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/path.zsh.inc"

    if [ ! $(echo $PATH | grep 'google-cloud-sdk') ]; then
        export CLOUDSDK_ROOT_DIR="$HOME/google-cloud-sdk"
        export PATH="$CLOUDSDK_ROOT_DIR/bin:$PATH"
    fi
fi

_command_exists python || return

export CLOUDSDK_PYTHON="$HOME/.pyenv/versions/3.7.11/envs/google-cloud-sdk-python/bin/python"
