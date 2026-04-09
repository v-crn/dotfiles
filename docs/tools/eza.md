# eza

`ls` の代替。アイコン表示・git 統合・ツリー表示が使いやすい。

## インストール

```zsh
# macOS
brew install eza

# Debian / Ubuntu
sudo apt install eza
```

## dotfiles でのエイリアス

`eza.zsh` で定義済み。eza がインストールされていなければ標準の `ls` が使われる。

| エイリアス | 展開 |
| --- | --- |
| `ls` | `eza --icons` |
| `ll` | `eza -lh --icons --git` |
| `la` | `eza -lha --icons --git` |
| `lt` | `eza --tree --icons` |

## Tips

```zsh
lt --level=2          # ツリーの深さを指定
ll --sort=modified    # 更新日時でソート
la --git-ignore       # .gitignore のファイルを非表示
```
