# .zsh/ について

zsh 関連のドットファイルをまとめたディレクトリ

## Rules

- パスなどの環境変数を記述したファイルは `.zshenv.d/` に配置
- プラグインの導入や独自関数を記述したファイルなどは `.zshrc.d/` に配置
- ファイルの読み込み順序に優先順位がある場合，ファイル名の先頭に 2 桁の数字を付けて小さいものから先に読み込まれるようにする
- `zshrc-options/` にあるのは実際には読み込まれないファイル
  - プラグインを使いたいときに `.zshrc.d/` フォルダに移動させることですぐ使えるように置いてある
- `.zshenv` が `.zsh/` の外側にも存在するのは zsh 設定ファイルの親ディレクトリを指定するパス `ZDOTDIR` を最初に与える必要があるため

## Usage

### Add plugins

基本的には次の形式で追加できる．

```sh
zinit light PLUGIN
```

- [awesome-zsh-plugins | Curated list of awesome lists | Project-Awesome.org](https://project-awesome.org/unixorn/awesome-zsh-plugins)

## 起動速度計測

5 回の試行例:

```sh
for i in $(seq 1 5); do time zsh -i -c exit; done
```

> ❯ for i in $(seq 1 5); do time zsh -i -c exit; done
> zsh -i -c exit 0.26s user 0.28s system 13% cpu 3.977 total
> zsh -i -c exit 0.25s user 0.24s system 85% cpu 0.577 total
> zsh -i -c exit 0.27s user 0.27s system 73% cpu 0.734 total
> zsh -i -c exit 0.25s user 0.24s system 79% cpu 0.619 total
> zsh -i -c exit 0.23s user 0.20s system 87% cpu 0.489 total
