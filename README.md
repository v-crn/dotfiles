# dotfiles

ドットファイル (dotfiles) の管理用リポジトリ

## Prerequests

- zsh
- zinit

## Installation

```sh
cd ~
git clone https://github.com/v-crn/dotfiles.git

cd dotfiles

# install dot
source zsh/.zshrc.d/dot.zsh
```

If your `dotfiles/` is not located at `~/dotfiles/`, please edit `DOT_DIR="$HOME/dotfiles"` in `zsh/.zshrc.d/dot.zsh` and then commit the above command.

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
