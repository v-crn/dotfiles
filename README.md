# dotfiles

ドットファイル (dotfiles) の管理用リポジトリ

## Prerequests

- zsh
- zinit

### Install zsh

[Installing ZSH · ohmyzsh/ohmyzsh Wiki](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)

```sh
sudo apt-get update -y && sudo apt-get install -y zsh
```

### Install zinit

zsh を起動した状態で以下のコマンドを実行する。

```sh
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
source ~/.local/share/zinit/zinit.git
```

## Installation

```sh
cd ~
git clone https://github.com/v-crn/dotfiles.git

# install dot
source ~/dotfiles/.zsh/.zshrc.d/dot.zsh
```

If your `dotfiles/` is not located at `~/dotfiles/`, please edit `DOT_DIR="$HOME/dotfiles"` in `.zsh/.zshrc.d/dot.zsh` and then commit the above command.

次のようなエラーが起きる場合、ファイルの権限を `chmod` コマンドで変更する必要がある。

> Downloading ssh0/dot…
> fatal: could not create leading directories of '/Users/v-crn/.zinit/plugins/ssh0---dot': Permission denied

```sh
sudo chmod -R 777 ~/.zinit/
```

## Usage

### Restore dotfiles from remote github repository

```sh
dot clear
dot update
zsh
```

- `dot clear`: 2 回目以降の更新でファイル名の変更などがある場合に必要
  - シンボリックリンクの実体が削除されると面倒なことになる
  - 更新でシンボリックリンクの実体を失ってしまったら，適当なファイルやディレクトリを作って dotlink を編集し， `dot set` でシンボリックリンクに再度実体を伴わせる
  - 読み込みに成功することを確認したら `dot unlink 不要なシンボリックリンク` でシンボリックリンクを外し，不要になったファイルなどを削除する

### Add a new dotfile from root directory

```sh
dot add ~/.dotfile
```

### Add a new dotfile in local `dotfiles/` directory

#### 1. Edit `dotlink`

Example:

```sh
# <file in dotfiles/>,<symbolic link>
.config/git,.config/git
zsh,zsh
.zshenv,.zshenv
```

#### 2. Set the symbolic links

```sh
dot set
```

## Dependency

- zsh plugin
  - [ssh0/dot](https://github.com/ssh0/dot)

## Ref

- [bto/dotfiles](https://github.com/bto/dotfiles)
