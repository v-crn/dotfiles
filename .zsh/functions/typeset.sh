# 重複パスを登録しない
typeset -U path cdpath fpath manpath

#   typeset
#    -U 重複パスを登録しない
#    -x exportも同時に行う
#    -T 環境変数へ紐付け
#
#   path=xxxx(N-/)
#     (N-/): 存在しないディレクトリは登録しない
#     パス(...): ...という条件にマッチするパスのみ残す
#        N: NULL_GLOBオプションを設定。
#           globがマッチしなかったり存在しないパスを無視する
#        -: シンボリックリンク先のパスを評価
#        /: ディレクトリのみ残す
#        .: 通常のファイルのみ残す

# Ref: [zshでHomebrewを使用する場合に設定しておいたほうが良いこと - よんちゅBlog](https://yonchu.hatenablog.com/entry/20120415/1334506855)
