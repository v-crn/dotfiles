zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
zinit light-mode for \
    tj/git-extras \
    paulirish/git-open

# Extending Git
zinit ice wait"2" lucid as"program" pick"bin/git-dsf"
zinit light zdharma-continuum/zsh-diff-so-fancy

zinit ice wait"2" lucid as"program" pick"git-now"
zinit light iwata/git-now

zinit ice wait"2" lucid as"program" pick"$ZPFX/bin/git-alias" make"PREFIX=$ZPFX" nocompile
zinit light tj/git-extras

zinit ice wait"2" lucid as"program" atclone'perl Makefile.PL PREFIX=$ZPFX' atpull'%atclone' \
    make'install' pick"$ZPFX/bin/git-cal"
zinit light k4rthik/git-cal
