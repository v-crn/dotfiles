# bat / batcat

`cat` の代替。シンタックスハイライト・行番号・git diff 表示付き。
Debian / Ubuntu では `batcat` というコマンド名になる。

## インストール

```zsh
# macOS
brew install bat

# Debian / Ubuntu
sudo apt install bat
```

## dotfiles でのエイリアス

`aliases.zsh` で定義済み。どちらもない場合は標準の `cat` が使われる。

| 環境 | 設定されるエイリアス |
| --- | --- |
| `bat` が使える | `cat='bat --paging=never'` |
| `batcat` が使える | `bat='batcat'`, `cat='batcat --paging=never'` |

## Tips

```zsh
bat --language=json file   # 言語を明示してハイライト
bat -n file                # 行番号のみ (ハイライトなし)
bat --diff file             # git diff をインライン表示
```

ページャーを使いたい場合は `--paging=always` または素の `bat` コマンドを使う。
