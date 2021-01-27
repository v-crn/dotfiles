.PHONY: rm_zsh
rm_zsh:
	rm -rf ${HOME}/.zshenv
	rm -rf ${HOME}/.zsh

.PHONY: add_zsh
add_zsh:
	\cp -f .zshenv ${HOME}/
	\cp -rf .zsh ${HOME}/
