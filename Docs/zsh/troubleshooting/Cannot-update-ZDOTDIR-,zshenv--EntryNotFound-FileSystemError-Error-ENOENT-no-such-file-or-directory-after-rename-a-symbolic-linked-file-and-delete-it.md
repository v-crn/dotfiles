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

---

`unlink zsh` 後に `dot update` しても同様の問題が起きた．

## Cause

シンボリック・リンクは名前を変更すると追随できない

## Solution

```sh
mkdir ~/zsh
touch ~/zsh/.zshenv
```

ここで新規起動で読み込み成功することを確認

```sh
❯ dot unlink /home/v-crn/zsh/.zshenv
unlink /home/v-crn/zsh/.zshenv
copy /home/v-crn/dotfiles/zsh/.zshenv
```

一旦 `~/dotfiles/zsh` を別名に変更し，あえて `~/dotfiles/zsh/.zshenv` を読み込ませないようにする

dotlink に次のリンクを記述

```sh
zsh/.zshenv,zsh/.zshenv
```

```sh
dot set
```

でシンボリックリンクを生成．これにより実体が消えていたシンボリックリンクに実体が伴うようになる

指定のシンボリックリンクを削除

```sh
❯ dot unlink /home/v-crn/zsh/.zshenv
unlink /home/v-crn/zsh/.zshenv
copy /home/v-crn/dotfiles/zsh/.zshenv
```

この状態になる:

```sh
❯ dot check
Loading /home/v-crn/dotfiles/dotlink ...
✔ /home/v-crn/dotfiles/.config/git,/home/v-crn/.config/git
✔ /home/v-crn/dotfiles/.zsh,/home/v-crn/.zsh
✘ /home/v-crn/dotfiles/.zshenv,/home/v-crn/.zshenv
✔ /home/v-crn/dotfiles/zsh/.zshenv,/home/v-crn/zsh/.zshenv
```

再度 zsh を新規起動すると読み込み成功することを確認

```sh
❯ dot check
Loading /home/v-crn/dotfiles/dotlink ...
✔ /home/v-crn/dotfiles/.config/git,/home/v-crn/.config/git
✔ /home/v-crn/dotfiles/.zsh,/home/v-crn/.zsh
✘ /home/v-crn/dotfiles/.zshenv,/home/v-crn/.zshenv
✘ /home/v-crn/dotfiles/zsh/.zshenv,/home/v-crn/zsh/.zshenv
```

再度シンボリックリンクを生成

```sh
❯ dot set
Loading /home/v-crn/dotfiles/dotlink ...
conflict File already exists at /home/v-crn/.zshenv.
Choose the operation:
    (d):show diff
    (e):edit files
    (f):replace
    (b):replace and make backup
    (n):do nothing
>>> f
done /home/v-crn/.zshenv
```

あとは不要になった zsh フォルダなどを削除

---

1. 新規に `~/zsh/` フォルダを作成
2. dotfiles 内に zsh フォルダが勝手に用意される（`~/zsh/` -> `~/dotfiles/zsh/` へのシンボリックリンクが貼られていたかも？）
3. 試しに `dotfiles/` 内の zsh フォルダを任意の場所に移動した後で新しく zsh 起動するときちんと変更後の `.zshenv` が読み込まれることを確認

状態

```sh
❯ ls ~
dotfiles zsh
```

4. 任意の場所に移動した zsh フォルダを削除しても同様に変更後の `.zshenv`　が読み込まれることを確認

---

最初の状態

```sh
$ ls
dotfiles zsh
```

- `env` コマンドで確認すると `ZDOTDIR=$HOME/zsh`

```sh
$ touch ~/dotfiles/zsh/.zshenv
```

~/dotfiles/zsh/.zshenv

dotfiles/.zshenv と同じ内容になるように編集する

```sh
# ZDOTDIR: zsh config root path
export ZDOTDIR=$HOME/.zsh
source $ZDOTDIR/.zshenv
```

新規 zsh 起動で正常に動作することを確認

~/dotfiles/zsh を削除

zsh を起動する正常に読み込まれる
