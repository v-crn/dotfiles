# starship

クロスシェル対応のプロンプト。設定ファイルは `~/.config/starship.toml`。

## インストール

```zsh
# macOS
brew install starship

# Linux / WSL2
curl -sS https://starship.rs/install.sh | sh
```

## dotfiles での管理

現時点では `starship.zsh` のみ管理対象で、`starship.toml` は管理していない。
必要になったら `chezmoi add ~/.config/starship.toml` で追加する。

## Tips

プロンプトに表示するモジュールを絞ると起動が速くなる。

```toml
# ~/.config/starship.toml
[battery]
disabled = true
```

公式のプリセット一覧: https://starship.rs/presets/
