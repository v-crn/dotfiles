# Claude settings.json スマートマージ設計

## 概要

`~/.claude/settings.json` を単純にコピーするのではなく、既存設定と dotfiles の望ましい設定をマージして適用する仕組みを導入する。

## 背景と目的

chezmoi の通常ファイルとして `settings.json` を管理すると、`chezmoi apply` のたびに全上書きされる。これにより以下の問題が生じる：

- `enabledPlugins` など、Claude Code が自動管理するキーが上書きされ実態と乖離する
- ローカルで手動追加した `permissions.allow` エントリが失われる

スマートマージにより、dotfiles を権威ある設定源としつつ、ツールや手動操作による設定変更を保持する。

## ファイル構成

### 変更前

```
home/dot_claude/
  settings.json
```

### 変更後

```
home/dot_claude/
  run_apply-claude-settings.sh     # マージスクリプト（chezmoi apply のたびに実行）
```

`settings.json` は削除し、desired 設定はスクリプト内のヒアドキュメントとして管理する。

## スクリプト動作

`chezmoi apply` のたびに `run_apply-claude-settings.sh` が実行される。

```
~/.claude/settings.json が存在しない
  → desired settings をそのまま書き込んで終了

~/.claude/settings.json が存在する
  → マージ戦略に従って jq でマージし、結果を書き込む
```

## マージ戦略

| キー | 戦略 | 理由 |
| --- | --- | --- |
| `env` | dotfiles で上書き | dotfiles が正 |
| `language` | dotfiles で上書き | dotfiles が正 |
| `statusLine` | dotfiles で上書き | dotfiles が正 |
| `sandbox`（スカラー・`excludedCommands`） | dotfiles で上書き | dotfiles が正 |
| `sandbox.network.allowedHosts` | union（重複なし） | ローカル追加を保持 |
| `enableAllProjectMcpServers` | dotfiles で上書き | dotfiles が正 |
| `enabledPlugins` | 既存を優先・dotfiles の新規キーを追加 | ツール自動管理の状態と乖離させない |
| `hooks` | 既存をそのまま保持、dotfiles に値があれば挿入 | ccstatusline 等の自動管理 hooks を尊重 |
| `permissions.disableBypassPermissionsMode` | dotfiles で上書き | dotfiles が正 |
| `permissions.allow` | union（重複なし） | ローカル追加を保持 |
| `permissions.deny` | union（重複なし） | ローカル追加を保持 |

### `enabledPlugins` の詳細

- 既存に存在するキーはそのまま保持（true/false 問わず）
- dotfiles にあって既存にないキーのみ追加
- dotfiles にないキーは削除しない

### `hooks` の詳細

- dotfiles の desired 設定は `"hooks": {}` （空オブジェクト）
- 既存の hooks エントリはすべて保持
- 将来 dotfiles にカスタム hooks を追加した場合、既存にないものを挿入

## スクリプト構造

```sh
#!/bin/sh
# -------------------------------------------------------
# Desired settings (edit this section to update settings)
# -------------------------------------------------------
DESIRED=$(cat <<'EOF'
{
  "env": { ... },
  "language": "Japanese",
  "statusLine": { ... },
  "sandbox": { ... },
  "enableAllProjectMcpServers": false,
  "enabledPlugins": { ... },
  "hooks": {},
  "permissions": { ... }
}
EOF
)

# -------------------------------------------------------
# Merge logic (rarely needs editing)
# -------------------------------------------------------
TARGET="$HOME/.claude/settings.json"

if [ ! -f "$TARGET" ]; then
  printf '%s\n' "$DESIRED" > "$TARGET"
  exit 0
fi

CURRENT=$(cat "$TARGET")

# jq を使ってキーごとのマージを実行
MERGED=$(echo "$CURRENT" | jq --argjson d "$DESIRED" '
  # ... マージロジック
')

printf '%s\n' "$MERGED" > "$TARGET"
```

## 依存ツール

- `jq` — JSON マージに使用。なければスキップして警告を出す

## 注意事項

- スクリプトは冪等である必要がある（何度実行しても同じ結果になること）
- dotfiles 側の desired 設定を変更したい場合はスクリプト上部の JSON を編集する
