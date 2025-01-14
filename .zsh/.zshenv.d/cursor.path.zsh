if [ -e "/mnt/c/Users/$windows_user/AppData/Local/Programs/cursor" ]; then
    export PATH="$PATH:/mnt/c/Users/$windows_user/AppData/Local/Programs/cursor/resources/app/bin"
    alias cursor="/mnt/c/Users/$windows_user/AppData/Local/Programs/cursor/resources/app/bin/cursor"
fi
