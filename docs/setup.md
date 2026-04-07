# セットアップ

## 前提条件

以下をインストールしておく。

```zsh
# macOS
brew install chezmoi zsh

# Debian / Ubuntu (WSL2 含む)
sudo apt install zsh
sh -c "$(curl -fsLS get.chezmoi.io)"
```

## ソースディレクトリ

default: `~/.local/share/chezmoi`
コマンドオプションで指定: `--source $CHEZMOI_SOURCE_DIR`

## 新規マシンへの適用手順

### 1. リポジトリを clone して chezmoi を初期化

```zsh
git clone <repo-url> ~/dotfiles
chezmoi init --source ~/dotfiles
```

### 2. chezmoi.toml を作成

テンプレートで使う変数を設定する。

```zsh
mkdir -p ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/chezmoi.toml
```

最低限の内容:

```toml
[data]
# 必要に応じて変数を追加
```

テンプレート変数の一覧は `chezmoi data` で確認できる。

### 3. 差分を確認して適用

```zsh
CHEZMOI_SOURCE_DIR=~/dotfiles
chezmoi diff --source $CHEZMOI_SOURCE_DIR    # 変更内容を確認
chezmoi apply --source $CHEZMOI_SOURCE_DIR    # 適用
```

### 4. sheldon プラグインをダウンロード

```zsh
sheldon lock
```

sheldon のインストールは [docs/tools/sheldon.md](tools/sheldon.md) を参照。

### 5. シェルを再起動

```zsh
exec zsh
```

## 既存マシンで更新を反映する

```zsh
cd ~/dotfiles
git pull
CHEZMOI_SOURCE_DIR=~/dotfiles
chezmoi diff --source $CHEZMOI_SOURCE_DIR
chezmoi apply --source $CHEZMOI_SOURCE_DIR
```

## トラブルシューティング

### `chezmoi managed` が空になる

`chezmoi managed` は設定ファイルで指定されたソースを参照する。
`--source` フラグで明示的に指定すると解決することがある。

```zsh
chezmoi --source ~/dotfiles managed
```

### `chezmoi apply` で対話的な確認が求められる

`--force` で確認をスキップできる (差分を事前に `chezmoi diff` で確認してから使う)。

```zsh
chezmoi apply --force
```

### zsh 起動が遅い

`sheldon source` の実行時間が原因のことが多い。`sheldon lock` でキャッシュを更新する。

```zsh
sheldon lock --update
```

### プラグインが読み込まれない

`sheldon lock` を再実行してキャッシュを再生成する。

```zsh
sheldon lock
exec zsh
```
