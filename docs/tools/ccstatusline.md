# ccstatusline

Claude Code のステータスラインをカスタマイズするツール。

## 概要

[ccstatusline](https://github.com/hcavarsan/ccstatusline) は Claude Code のステータスバーに表示する情報をカスタマイズできる CLI ツール。モデル名・思考量・コンテキスト使用率・トークン数・Git 情報などをステータスラインに表示する。

## 設定ファイル

| ファイル | 用途 |
| --- | --- |
| `~/.config/ccstatusline/settings.json` | 表示レイアウト・色・各ウィジェットの設定 |

chezmoi ソース: `home/dot_config/ccstatusline/settings.json`

## Claude Code への組み込み

`~/.claude/settings.json` の `statusLine` セクションで設定する:

```json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y ccstatusline@latest",
    "padding": 0
  }
}
```

## ウィジェット一覧

| type | 表示内容 |
| --- | --- |
| `model` | 使用中のモデル名 |
| `thinking-effort` | 思考モードの設定値 |
| `context-percentage` | コンテキストウィンドウ使用率 |
| `session-usage` | セッション内トークン使用量 |
| `tokens-total` | 累計トークン数 |
| `tokens-cached` | キャッシュ済みトークン数 |
| `weekly-usage` | 週次トークン使用量 |
| `reset-timer` | セッションリセットまでの残り時間 |
| `weekly-reset-timer` | 週次リセットまでの残り時間 |
| `git-root-dir` | Git リポジトリ名 |
| `git-branch` | 現在のブランチ名 |
| `git-changes` | 変更ファイル数 |
| `git-worktree` | worktree 名 |
| `skills` | ロード済みスキル数 |
| `separator` | 区切り文字 |

## 設定のカスタマイズ

`settings.json` を編集後、`chezmoi apply` で `~/.config/ccstatusline/settings.json` に反映する:

```zsh
# 設定ファイルを直接編集
$EDITOR home/dot_config/ccstatusline/settings.json

# 反映
chezmoi apply
```
