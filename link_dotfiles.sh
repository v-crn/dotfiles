set -u
DOT_DIR=~/dotfiles
cd $DOT_DIR
git submodule init
git submodule update

echo "start setup..."
for f in .??*; do
    # Files don't need to be linked
    [ "$f" = ".git" ] && continue
    [ "$f" = ".gitignore" ] && continue
    [ "$f" = ".gitconfig" ] && continue
    [ "$f" = ".gitconfig.local.template" ] && continue
    [ "$f" = ".gitmodules" ] && continue
    [[ "$f" == ".DS_Store" ]] && continue
    [ "$f" = ".bash_sessions" ] && continue
    [ "$f" = ".bash_history" ] && continue
    [ "$f" = ".zcompdump.zwc" ] && continue
    [ "$f" = ".zcompdump" ] && continue
    [ "$f" = ".zprezto" ] && continue

    ln -snfv $DOT_DIR/"$f" ~/
done

[ -e ~/.gitconfig.local ] || cp $DOT_DIR/.gitconfig.local.template ~/.gitconfig.local

# emacs set up
if which cask >/dev/null 2>&1; then
  echo "setup .emacs.d..."
  cd ${DOT_DIR}/.emacs.d
  cask upgrade
  cask install
fi

cat << END

**************************************************
DOTFILES SETUP FINISHED! bye.
**************************************************

END
