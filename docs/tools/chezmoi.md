# chezmoi

[chezmoi](https://www.chezmoi.io/) は、複数のマシン間で dotfiles を管理するためのツールです。

## chezmoi File Naming Conventions

| Prefix/Suffix | Effect |
| --- | --- |
| `dot_` prefix | Rename to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `private_` prefix | Set permissions to 0600 |
| `.tmpl` suffix | Process as Go template |
| `run_once_` prefix | Execute only once |

## Common Commands

```bash
chezmoi add ~/.zshrc --source .    # 管理対象に追加
chezmoi edit ~/.zshrc --source .   # 管理対象ファイルを編集
chezmoi diff --source .            # ソースと適用先の差分を表示
chezmoi apply -n --source .        # ドライラン（適用せずに確認のみ）
chezmoi apply --source .           # ホームディレクトリへ適用
chezmoi managed --source .         # 管理対象ファイルの一覧を表示
chezmoi cd --source .              # ソースディレクトリへ cd
chezmoi data --source .            # テンプレート変数を表示
```

## Further info

- [chezmoi.io](https://www.chezmoi.io/)
- [twpayne/chezmoi (GitHub)](https://github.com/twpayne/chezmoi)
- [chezmoi_io (context7)](https://context7.com/websites/chezmoi_io)
- [twpayne/chezmoi (context7)](https://context7.com/twpayne/chezmoi)
