# sheldon

zsh プラグインマネージャ。設定ファイルは `~/.config/sheldon/plugins.toml`。

## インストール

```zsh
# macOS
brew install sheldon

# Linux / WSL2
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
```

## 現在のプラグイン

| プラグイン | 用途 |
|-----------|------|
| zsh-autosuggestions | 入力中にヒストリから候補を薄字表示 (→ で確定) |
| zsh-completions | 各種ツールの補完定義を追加 |
| zsh-autopair | 括弧・クォートを自動で閉じる |
| zsh-history-substring-search | ↑↓ で入力済み文字列のサブストリング検索 |
| zsh-you-should-use | エイリアスがある操作を素のコマンドで打つと教えてくれる |
| fzf-tab | Tab 補完を fzf UI に置き換える (fzf が必要) |
| zsh-syntax-highlighting | コマンドラインのシンタックスハイライト (最後にロード必須) |

## プラグインを追加する

```zsh
# 1. plugins.toml を編集
chezmoi edit ~/.config/sheldon/plugins.toml

# 2. ダウンロードしてロック
sheldon lock

# 3. 反映確認
exec zsh
```

### 読み込み順の注意点

- `zsh-syntax-highlighting` は必ず最後に置く (ZLE ウィジェットをラップする仕組みのため)
- `fzf-tab` は `compinit` 後にロードが必要なため `apply = []` で sheldon の自動ソースを無効化し、`completion.zsh` で手動ロードしている

## よく使うコマンド

```zsh
sheldon lock           # プラグインをダウンロード・ロックファイル更新
sheldon lock --update  # 全プラグインを最新版に更新
sheldon source         # ロードスクリプトを出力 (デバッグ用)
```
