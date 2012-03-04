#!/bin/sh

##
# Installation of Twgit.
#
# In the directory of your choice, e.g. ~/twgit:
#   git clone git@github.com:Twenga/twgit.git .
#   sudo make install
#
# @author Geoffroy Aubry <geoffroy.aubry@free.fr>
#



ROOT_DIR:="`pwd`"
BIN_DIR:="/usr/local/bin"
BASH_COMPLETION_DIR:="/etc/bash_completion.d"
CONF_DIR:="${ROOT_DIR}/conf"
INSTALL_DIR:="${ROOT_DIR}/install"
CURRENT_BRANCH:="`git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g'`"

.PHONY: all help install uninstall

default: help

help:
	@echo "Usage: make install"
	@echo "       make uninstall"

install:
	@if [ "${CURRENT_BRANCH}" != "stable" ]; then \
		echo "You must be on 'stable' branch, not on '${CURRENT_BRANCH}' branch! Try: git checkout --track -b stable origin/stable"; \
		exit 1; \
	fi

	@echo "Install '${BIN_DIR}/twgit'"
	@ln -sf ${ROOT_DIR}/twgit ${BIN_DIR}/twgit
	@chmod 0755 ${BIN_DIR}/twgit

	@echo "Install Bash completion: '${BASH_COMPLETION_DIR}/twgit'"
	@ln -sf ${ROOT_DIR}/install/bash_completion.sh ${BASH_COMPLETION_DIR}/twgit

	@if test -f "${CONF_DIR}/twgit.sh"; then \
		echo "Config file '${CONF_DIR}/twgit.sh' already existing."; \
	else \
		echo "Copy config file from '${CONF_DIR}/twgit-dist.sh' to '${CONF_DIR}/twgit.sh'"; \
		cp -n "${CONF_DIR}/twgit-dist.sh" "${CONF_DIR}/twgit.sh"; \
	fi

	@if test ! -z "`cat ~/.bashrc | grep -E '\.bash_git' | grep -vE '^#'`"; then \
		echo "Colored Git prompt already loaded by '${HOME}/.bashrc'."; \
	else \
		echo -n "Add colored Git prompt to '${HOME}/.bashrc' ? [Y/N] "; \
		read answer; \
		if [ "$$answer" = "Y" ] || [ "$$answer" = "y" ]; then \
			install -m 0644 "${INSTALL_DIR}/bash_git.sh" "${HOME}/.bash_git"; \
			echo "Add '. ~/.bash_git' at end of '${HOME}/.bashrc'."; \
			echo "\n# Added by Twgit makefile:\n. ~/.bash_git" >> ${HOME}/.bashrc; \
		fi \
	fi

uninstall:
	rm -f "${BIN_DIR}/twgit"
	rm -f "${BASH_COMPLETION_DIR}/twgit"
