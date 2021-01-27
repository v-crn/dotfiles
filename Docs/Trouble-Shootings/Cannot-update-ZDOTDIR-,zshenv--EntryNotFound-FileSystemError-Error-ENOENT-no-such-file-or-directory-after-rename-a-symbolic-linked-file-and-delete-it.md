# Cannot update ZDOTDIR in .zshenv; EntryNotFound (FileSystemError): Error: ENOENT: no such file or directory

## Problem

zsh の起動時に .zshrc などが読み込まれない

それまでに行っていたこと（思い出せる限り）:

1. `dotfiles/` 内に元々存在していた zsh を .zsh にファイル名変更
2. `rm -rf ~/zsh` を実行（シンボリックリンクが貼られているのでやるべきではなかった）
3. `rm -rf ~/.zshenv` を実行（シンボリックリンクが貼られているのでやるべきではなかった）
4. 変更を `git push` し，`dot update` をかける
5. zsh の起動時に .zshrc などが読み込まれない

- 上記以外にも `link` や `unlink` コマンドをいくつか実行していた
- `env` コマンドで環境変数を確認すると，`ZDOTDIR` が変更前の `$HOME/zsh` のままになっている
- git の差分で `zsh` という名前のファイルが変更されていると通知され，標題のエラーが出る

## Solution

1. 新規に `~/zsh/` フォルダを作成
2. dotfiles 内に zsh フォルダが勝手に用意される（`~/zsh/` -> `~/dotfiles/zsh/` へのシンボリックリンクが貼られていたかも？）
3. 試しに `dotfiles/` 内の zsh フォルダを任意の場所に移動した後で新しく zsh 起動するときちんと変更後の `.zshenv` が読み込まれることを確認
4. 任意の場所に移動した zsh フォルダを削除しても同様に変更後の `.zshenv`　が読み込まれることを確認
