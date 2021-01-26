# g: git
alias g='git'

# gst: git status
alias gst='git status'

# gad: git add
alias gad='git add'

# gc: checkout
alias gc='git checkout'

# gci: git checkout issues
alias gci='gci'
function gci() {
    git checkout issues/$@
}

# gcb: checkout with a new branch
alias gcb='git checkout -b'
alias gcbi='gcbi'
function gcbi() {
    git checkout -b issues/$@
}

# gsw: git switch; git checkout
alias gsw='git switch'

# gswc: git witch -c; git checkout -b
alias gswc='git switch - c'

# gres: git restore
alias gres='git restore'

# gpl: git pull
alias gpl='git pull'

# gplr: pull the PR branch
alias gplr='gplr'
function gplr() {
    git fetch upstream pull/$@/head:pr/$@ && git checkout pr/$@
}

# gp: push
alias gp='git push'
alias gpo='git push origin'
alias gpups='git push --set-upstream origin master'
alias gpoi='gpoi'
function gpoi() {
    git push origin issues/$@
}

# gf: fetch
alias gf='git fetch'

# gbra: show all branches
alias gbra='git branch -a -vv'

# gl: show logs of current branch
alias gl='git log --graph --date=short'

# gla: show logs of all branches
alias gla='git log --oneline --decorate --graph --branches --tags --remotes'

# gsv: save all files including untracked
alias gss='git stash save -u'

# gsl: check stash
alias gsl='git stash list'

# gi: auto-generate .gitignore from gitignore.io
## Usage: gi ruby >> .gitignore
alias gi='gi'
function gi() {
    curl -sLw n https://www.toptal.com/developers/gitignore/api/$@
}
