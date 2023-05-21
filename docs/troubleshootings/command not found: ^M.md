# command not found: ^M

## 問題

wsl2, zsh, zinit の環境で次のエラーが発生しました。

```console
/home/username/.zsh^M/.zshenv:7: command not found: ^M
/home/username/.zsh^M/.zshenv:28: parse error near `\n'
/home/username/.zsh^M/.zshrc:.:4: no such file or directory: /home/username/.zsh^M/functions/typeset.sh^M
/home/username/.zsh^M/.zshrc:5: command not found: ^M
/home/username/.zsh^M/.zshrc:.:9: no such file or directory: /home/username/.zsh^M/functions/_sources.sh^M
/home/username/.zsh^M/.zshrc:10: no matches found: /home/username/.zsh^M/.zshrc.d/*.zsh(N-.)^M
/home/username/.zsh^M/.zshrc:11: command not found: ^M
/home/username/.zsh^M/.zshrc:27: parse error near `\n'
```

## 解決方法

GPT-4 が解決してくれました。
結論だけ言うと次のコマンドで改行コードを Unix 用の LF に変更すればOKでした。

```bash
find ~/dotfiles/.zsh -type f \( -name "*.sh" -o -name "*.zsh" \) -exec dos2unix {} \;
```

以下、詳細。

---

エラーメッセージに含まれる^Mは、通常、WindowsとUnix系（Linux, macOSなど）で改行コードの扱いが異なることが原因で表示されます。具体的には、Windowsは改行としてCR+LF (Carriage Return + Line Feed)を、Unix系はLF (Line Feed)を使用します。Windows上で作成・編集されたテキストファイルをUnix系のシステムで開くと^Mとして表示されることがあります。

解決するには、以下のように改行コードをUnix形式（LF）に変換します。これには dos2unix というツールを使います。もしまだインストールされていなければ、sudo apt-get install dos2unix のようにしてインストールしてください。

以下に手順を示します:

WSL2 のシェルにログインします。

dos2unix コマンドを使って改行コードを変換します:

```bash
dos2unix /home/username/.zsh/.zshenv
dos2unix /home/username/.zsh/.zshrc
dos2unix /home/username/.zsh/functions/typeset.sh
dos2unix /home/username/.zsh/functions/_sources.sh
```

この操作により、ファイルの改行コードが LF に変換され、エラーメッセージが消えるはずです。エラーが続く場合や、別の問題が発生した場合には、再度詳細な情報を提供してください。

### 改行コードをOSに依存しないようにする方法はありませんか？

OSに依存しないように改行コードを扱うには、主に以下の二つの方法があります。

#### テキストエディタの設定

多くのテキストエディタでは、改行コードの種類を設定することができます。例えば、VSCodeでは、右下のステータスバーに現在の改行コードが表示され、これをクリックすることで変更することができます。また、新規ファイルのデフォルトの改行コードを設定することも可能です。これは"files.eol"設定で"\n"（LF）または"\r\n"（CRLF）に設定できます。

#### Gitの設定

Gitには改行コードの自動変換機能があります。core.autocrlf設定を使って、コミット時にLFに、チェックアウト時にはシステムのデフォルトに変換することができます。Windowsでは以下のように設定します:

```bash
git config --global core.autocrlf true
```

Unix系のOSでは、以下のように設定します:

```bash
git config --global core.autocrlf input
```

この二つの方法を組み合わせて使用することで、OS間で改行コードの違いによる問題をほぼ防ぐことができます。ただし、既にリポジトリにコミットされたファイルの改行コードは自動的には変わらないので、必要に応じて手動で変換することも忘れないようにしましょう。

### 一括でファイルの改行コードを変更するコマンド

`find` と `dos2unix` を組み合わせて、特定のディレクトリ以下の全てのファイルの改行コードを一括で変更することができます。次のコマンドは `/home/username/.zsh` ディレクトリ以下の全ての .sh と .zsh ファイルを対象にします。

```bash
find /home/username/.zsh -type f \( -name "*.sh" -o -name "*.zsh" \) -exec dos2unix {} \;
```

このコマンドは以下のように動作します:

`find /home/username/.zsh -type f \( -name "*.sh" -o -name "*.zsh" \)` で、指定したディレクトリ以下の全ての .sh または .zsh ファイルを検索します。
`-exec dos2unix {} \;` で、検索した各ファイルに対して `dos2unix` コマンドを実行します。
ただし、このコマンドを実行する前に、重要なファイルのバックアップを取っておくことをお勧めします。また、このコマンドは対象のディレクトリとその下位の全てのディレクトリを対象にするため、大量のファイルがある場合には実行に時間がかかることがあります。
