"""
[darvid/zsh-poetry: 🐚 Simple ZSH plugin for automatically activating and deactivating Poetry-created virtualenvs. 🐍](https://github.com/darvid/zsh-poetry)

Automatically activates virtual environments created by Poetry when changing to a project directory with a valid pyproject.toml.

Also patches poetry shell to work more reliably, especially in environments using pyenv.
"""
zinit ice has"poetry"
zinit load darvid/zsh-poetry
