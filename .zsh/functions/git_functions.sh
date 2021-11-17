# github_main_name などの環境変数は dotfiles/.env に定義すること

function gitmain() {
  git config --global user.name ${github_main_name}
  git config --global user.email ${github_main_email}
}

function gitsub() {
  git config --global user.name ${github_sub_name}
  git config --global user.email ${github_sub_email}
}
