set -u
DOT_DIR=$HOME/dotfiles
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

  ln -snfv $DOT_DIR/"$f" $HOME/
done

[ -e $HOME/.gitconfig.local ] || cp $DOT_DIR/.gitconfig.local.template $HOME/.gitconfig.local

cat <<END

**************************************************
DOTFILES SETUP FINISHED! bye.
**************************************************

END
