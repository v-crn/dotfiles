# fzf

インタラクティブなファジーファインダー。このリポジトリでは主に **fzf-tab** 経由で使う。

## インストール

```zsh
# macOS
brew install fzf

# Debian / Ubuntu
sudo apt install fzf

# mise で管理する場合
mise use --global fzf
```

## fzf-tab との連携

fzf がインストールされていると、Tab 補完が fzf のインタラクティブ UI に切り替わる。
`completion.zsh` 内で `command -v fzf` を確認し、ある場合のみ fzf-tab をロードする。

## Tips

### よく使うキー操作 (fzf-tab)

| キー | 動作 |
|------|------|
| `Tab` | 候補を選択 |
| `Shift+Tab` | 複数選択 |
| `Enter` | 確定 |
| `Ctrl+C` / `Esc` | キャンセル |

### fzf 単体での使い方

```zsh
# ファイル選択して vim で開く
vim $(fzf)

# ヒストリ検索
history | fzf

# プロセス選択して kill
kill $(ps aux | fzf | awk '{print $2}')
```

### 環境変数によるカスタマイズ

`~/.zshenv` に追記することで fzf のデフォルト動作を変更できる。

```zsh
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f'   # fd がある場合
```
