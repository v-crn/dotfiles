# Coding Agents 設定管理

`~/.agents/` を共通ルールのリポジトリとして、複数の coding agents ツールが設定を共有する構成。

## 構成

```text
~/.agents/
├── AGENTS.md          # エントリーポイント（chezmoi が環境に合わせて生成）
└── rules/
    ├── common/        # 常時適用ルール
    ├── wsl/           # WSL 固有ルール
    ├── macos/         # macOS 固有ルール
    └── workspace/     # ワークスペース別ルール
```

## 各ツールの参照方式

| ツール | ファイル | 方式 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/AGENTS.md` で委譲 |
| Gemini CLI | `~/.gemini/GEMINI.md` | `@~/.agents/AGENTS.md` で委譲 |
| Codex CLI | `~/.agents/AGENTS.md` | 直接参照 |
| Cursor | `~/.cursor/rules/global.mdc` | chezmoi テンプレートでインライン展開 |

## 環境判定ロジック

`~/.agents/AGENTS.md` は chezmoi テンプレート（`home/dot_agents/AGENTS.md.tmpl`）から生成される。

| 条件 | 判定方法 | 追加されるルール |
| --- | --- | --- |
| WSL 環境 | `chezmoi.kernel.osrelease` に `"microsoft"` を含む | `rules/wsl/coding-style.md` |
| 非 personal ワークスペース | `workspace != "personal"`（`chezmoi.toml` で設定） | `rules/workspace/<name>.md` |

## ワークスペース設定

デフォルトは `"personal"`。職場マシンでは `~/.config/chezmoi/chezmoi.toml` に以下を追記する（Git 管理外）:

```toml
[data]
workspace = "work-acme"
```

対応するルールファイル `home/dot_agents/rules/workspace/work-acme.md` を作成し、`chezmoi apply` を実行する。

## ルール追加手順

1. `home/dot_agents/rules/<category>/<name>.md` を作成
2. 必要に応じて `home/dot_agents/AGENTS.md.tmpl` に判定条件と参照行を追加
3. Cursor も更新が必要な場合は `home/dot_cursor/rules/global.mdc.tmpl` も編集
4. `chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl` でレンダリングを確認
5. `chezmoi apply` で反映

## テンプレートの確認コマンド

```zsh
# AGENTS.md のレンダリング確認
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl

# 現在の環境変数（chezmoi テンプレート変数）を確認
chezmoi data

# 適用前の差分確認
chezmoi diff
```
