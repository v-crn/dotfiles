# dotfiles

ドットファイル (dotfiles) の管理用リポジトリ

## Prerequests

- zsh
- zinit

For Ubuntu minimal:

- column (required by git-extras)
- locales-all (required by git-cal)

### Install zsh

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Install zinit

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
source "$HOME/.zinit/bin/zinit.zsh"
```

### For Ubuntu minimal

#### Install column

Ubuntu の最小構成版 (ex: Ubuntu 18.04.05 LTS (Bionic Beaver)) を使用している場合，zsh プラグイン git-extras の導入時に次のエラーが出る．

> Need to install dependency 'column' before installation

git-extras の依存パッケージ `column` を含む `bsdmainutils` をインストールすると解決する．

```sh
sudo apt update && sudo apt install bsdmainutils
```

- [command-not-found.com – column](https://command-not-found.com/column)
- [column コマンドを Ubuntu にインストール - Qiita](https://qiita.com/suzuki-navi/items/d9228fc776a571ef16c9)

#### Install locales-all

```sh
sudo apt install locales-all
```

## Installation

```sh
cd ~
git clone https://github.com/v-crn/dotfiles.git
cd dotfiles

# install dot
source .zsh/.zshrc.d/dot.zsh
```

If your `dotfiles/` is not located at `~/dotfiles/`, please edit `DOT_DIR="$HOME/dotfiles"` in `.zsh/.zshrc.d/dot.zsh` and then commit the above command.

## Usage

### Restore dotfiles from remote github repository

```sh
dot update
zsh
```

### Add a new dotfile from root directory

```sh
dot add ~/.dotfile
```

After above, commit changes to git.

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

After above, commit changes to git.

## Dependency

- zsh plugin
  - [ssh0/dot](https://github.com/ssh0/dot)

## Ref.

[bto/dotfiles](https://github.com/bto/dotfiles)
