# dotfiles

ドットファイル (dotfiles) の管理用リポジトリ

## Prerequests

- [ssh0/dot: Simplest dotfiles manager written in shellscript](https://github.com/ssh0/dot)

## Installation

```sh
git clone https://github.com/v-crn/dotfiles.git
```

```sh
export DOT_REPO="https://github.com/your_username/dotfiles.git"
export DOT_DIR="$HOME/.dotfiles"
```

## Usage

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

### Restore dotfiles from remote github repository

```sh
dot update
```

## .gitignore の設定について

エディタやシェルにプラグインを入れると， dotfiles 管理下のディレクトリに自動的にファイルが作られることがある．他のファイルが追加されても更新があるように見えないようにするため，.gitignore をホワイトリスト形式で記述する．
