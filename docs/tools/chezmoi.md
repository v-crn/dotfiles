# chezmoi

chezmoi は、複数のマシン間で dotfiles を管理するためのツールです。

## chezmoi File Naming Conventions

| Prefix/Suffix | Effect |
| --- | --- |
| `dot_` prefix | Rename to `.` (e.g. `dot_zshrc` → `.zshrc`) |
| `executable_` prefix | Deploy with execute permission (`chmod +x`) — stripped from target name |
| `private_` prefix | Set permissions to 0600 |
| `readonly_` prefix | Set permissions to 0444 |
| `.tmpl` suffix | Process as Go template |
| `run_once_` prefix | Execute script once (not deployed as a file) |
| `run_` prefix | Execute script on every apply (not deployed as a file) |

### executable_ prefix の注意点

chezmoi はソースファイルの実際のパーミッション（`chmod +x`）を**無視**する。
実行可能ファイルとしてデプロイするには必ず `executable_` プレフィックスが必要。

```text
home/dot_claude/hooks/
  executable_pre-tool-use.sh   # → ~/.claude/hooks/pre-tool-use.sh (chmod +x)
  lib/
    executable_platform.sh     # → ~/.claude/hooks/lib/platform.sh (chmod +x)
```

スクリプト内部からの相互参照は **デプロイ後のファイル名**（プレフィックスなし）で記述する:

```bash
# ✅ 正しい（デプロイ後の名前を参照）
. "$HOOK_DIR/lib/notify.sh"

# ❌ 誤り（ソース名を参照してもデプロイ先に存在しない）
. "$HOOK_DIR/lib/executable_notify.sh"
```

### テストの配置方針

ソースファイルから直接実行するテストは内部参照の名前不一致で失敗する。
**デプロイ済みパス（`~/.claude/hooks/` 等）を対象にする**ことで本番動作を検証できる。

```bash
# tests/test_hooks.bats
HOOKS_DIR="$HOME/.claude/hooks"   # デプロイ済みスクリプトをテスト
```

CI では `chezmoi apply` を先に実行してからテストを走らせる。

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
