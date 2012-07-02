#!/bin/sh

##
# Installation of Twgit.
#
# In the directory of your choice, e.g. ~/twgit:
#   git clone git@github.com:Twenga/twgit.git .
#   sudo make install
#
#
#
# Copyright (c) 2011 Twenga SA
# Copyright (c) 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance 
# with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
# for the specific language governing permissions and limitations under the License.
#
# @copyright 2011 Twenga SA
# @copyright 2012 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @license http://www.apache.org/licenses/LICENSE-2.0
#



ROOT_DIR:=$(shell pwd)
BIN_DIR:="/usr/local/bin"
BASH_COMPLETION_DIR:="/etc/bash_completion.d"
CONF_DIR:="$(ROOT_DIR)/conf"
INSTALL_DIR:="$(ROOT_DIR)/install"
CURRENT_BRANCH:=$(shell git branch --no-color | grep '^\* ' | grep -v 'no branch' | sed 's/^* //g')

uname:="$(shell uname)"
OS:="$(shell if [ "$(uname)" = "FreeBSD" ] || [ "$(uname)" = "Darwin" ]; then echo "MacOSX"; else echo "Linux"; fi)"
BASH_RC:="$(shell if [ "$(OS)" = "MacOSX" ]; then echo "${HOME}/.bash_profile"; else echo "${HOME}/.bashrc"; fi)"

.PHONY: all doc help install uninstall

default: help

doc:
	bash $(INSTALL_DIR)/command_prompt_screenshots.sh "$(ROOT_DIR)"

help:
	@echo "Usage:"
	@echo "    sudo make install: to install Twgit in $(BIN_DIR), bash completion, config file and colored git prompt"
	@echo "    sudo make uninstall: to uninstall Twgit from $(BIN_DIR) and bash completion"
	@echo "    make doc: to generate screenshots of help on command prompt"

install:
	@if [ $(shell whoami) != "root" ]; then \
		echo "Sorry, you are not root."; \
		exit 1; \
	fi
	@if [ "$(CURRENT_BRANCH)" != "stable" ]; then \
		echo "You must be on 'stable' branch, not on '$(CURRENT_BRANCH)' branch! Try: git checkout --track -b stable origin/stable"; \
		exit 2; \
	fi

	@echo "\nInstall executable '$(BIN_DIR)/twgit'."
	@echo '#!/bin/bash\n/bin/bash "'$(ROOT_DIR)'/twgit" $$@' > $(BIN_DIR)/twgit
	@chmod 0755 $(BIN_DIR)/twgit

	@echo "\nInstall Twgit Bash completion:"
	@if test ! -z "`cat $(BASH_RC) | grep -E '/bash_completion.sh' | grep -vE '^#'`"; then \
		echo "Twgit Bash completion already loaded by '$(BASH_RC)'."; \
	else \
		echo "Add line '. $(ROOT_DIR)/install/bash_completion.sh' at end of script '$(BASH_RC)'."; \
		echo "\n# Added by Twgit makefile:\n. $(ROOT_DIR)/install/bash_completion.sh" >> $(BASH_RC); \
		echo "Restart bash session to enable autocompletion."; \
	fi

	@echo "\nCheck Twgit config file:"
	@if test -f "$(CONF_DIR)/twgit.sh"; then \
		echo "Config file '$(CONF_DIR)/twgit.sh' already existing."; \
	else \
		echo "Copy config file from '$(CONF_DIR)/twgit-dist.sh' to '$(CONF_DIR)/twgit.sh'"; \
		cp -p -n "$(CONF_DIR)/twgit-dist.sh" "$(CONF_DIR)/twgit.sh"; \
	fi

	@echo "\nInstall colored git prompt:"
	@if test ! -z "`cat $(BASH_RC) | grep -E '\.bash_git' | grep -vE '^#'`"; then \
		echo "Colored Git prompt already loaded by '$(BASH_RC)'."; \
	else \
		echo -n "Add colored Git prompt to '$(BASH_RC)' ? [Y/N] "; \
		read answer; \
		if [ "$$answer" = "Y" ] || [ "$$answer" = "y" ]; then \
			echo "Install bash git prompt: $(HOME)/.bash_git"; \
			install -m 0644 -o $(SUDO_UID) -g $(SUDO_GID) "$(INSTALL_DIR)/bash_git.sh" "$(HOME)/.bash_git"; \
			echo "Add line '. ~/.bash_git' at end of script '$(BASH_RC)'."; \
			echo "\n# Added by Twgit makefile:\n. ~/.bash_git" >> $(BASH_RC); \
		fi \
	fi

uninstall:
	@if [ $(shell whoami) != "root" ]; then \
		echo "Sorry, you are not root."; \
		exit 3; \
	fi
	rm -f "$(BIN_DIR)/twgit"
	rm -f "$(BASH_COMPLETION_DIR)/twgit"
