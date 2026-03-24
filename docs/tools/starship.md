# starship

クロスシェル対応のプロンプト。設定ファイルは `~/.config/starship.toml`。

## インストール

```zsh
# macOS
brew install starship

# Linux / WSL2
curl -sS https://starship.rs/install.sh | sh
```

## dotfiles での管理ファイル

| ファイル | 役割 |
|---------|------|
| `home/dot_config/zsh/starship.zsh` | `eval "$(starship init zsh)"` を実行。starship がなければ何もしない。 |
| `home/dot_config/starship.toml` | プロンプトの見た目・モジュール設定 |

## プロンプトレイアウト

```
~/projects/app  main +2 ~1  v20.11  3s
❯
                                  14:32:05  (右プロンプト)
```

**2行構成 + 右プロンプト:**

- 1行目: ディレクトリ / Git 情報 / 言語バージョン / コマンド実行時間
- 2行目: `❯` のみ (成功=緑、失敗=赤、Vim モード=黄)
- 右プロンプト: 時刻 + 終了コード (0以外のみ)

> Nerd Font をインストールするとアイコンが正しく表示される。
> ([Nerd Fonts](https://www.nerdfonts.com/) — ターミナルフォントとして設定が必要)

## 有効モジュール

| モジュール | 表示条件 | 内容 |
|-----------|---------|------|
| `username` | SSH または root 時のみ | ユーザー名 |
| `hostname` | SSH 時のみ | ホスト名 |
| `directory` | 常時 | 最大4階層、短縮表示あり |
| `git_branch` | Git リポジトリ内 | ブランチ名 |
| `git_status` | Git リポジトリ内 | 変更状況 (+/-/? など) |
| `git_metrics` | Git リポジトリ内 | 追加/削除行数 |
| `nodejs` | `package.json` 等が存在する場合 | Node.js バージョン |
| `python` | `*.py` 等が存在する場合 | Python バージョン + virtualenv |
| `rust` | `Cargo.toml` 等が存在する場合 | Rust バージョン |
| `golang` | `go.mod` 等が存在する場合 | Go バージョン |
| `docker_context` | `Dockerfile` 等が存在する場合 | Docker コンテキスト名 |
| `cmd_duration` | コマンドが 2秒以上かかった場合 | 実行時間 |
| `time` (右) | 常時 | 現在時刻 |
| `status` (右) | 終了コードが 0 以外の場合 | 終了コード |

## 無効モジュール

パフォーマンスとノイズ削減のため以下を無効化:
`battery`, `package`, `aws`, `gcloud`, `azure`, `terraform`, `vagrant`, `conda`, `nix_shell`, `spack`

必要なときは一時的に有効化できる:

```zsh
starship toggle aws    # aws モジュールを有効/無効切替
```

## カスタマイズ

設定ファイルを直接編集する:

```zsh
chezmoi edit ~/.config/starship.toml
chezmoi apply
```

## Tips

```zsh
starship explain       # 現在のプロンプト構成を解説表示
starship timings       # 各モジュールのレンダリング時間を計測
starship bug-report    # バグレポート用情報を収集
```

### モジュールを追加したいとき

`starship.toml` の `format` に追加し、モジュールセクションを記述する:

```toml
# format の末尾（line_break の前）に追加
format = """
...
$ruby\    # 追加
$line_break\
$character"""

[ruby]
symbol = " "
```

利用可能なモジュール一覧: https://starship.rs/config/
