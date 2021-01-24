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

### Add a new dotfile in local `dotfiles/` directory

```sh
dot set $DOT_DIR/.dotfile
```

### Restore dotfiles from remote github repository

```sh
dot update
```

## .gitignore の設定について

エディタやシェルにプラグインを入れると， dotfiles 管理下のディレクトリに自動的にファイルが作られることがある．他のファイルが追加されても更新があるように見えないようにするため，.gitignore をホワイトリスト形式で記述する．
