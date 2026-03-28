# .Net SDK path
if [ -e "$HOME/.dotnet" ]; then
    export DOTNET_ROOT=$HOME/.dotnet
    export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
fi
if [ -e "/usr/local/share/dotnet" ]; then
    export PATH="${PATH}:/usr/local/share/dotnet"
fi
