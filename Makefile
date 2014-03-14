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
# Copyright (c) 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# Copyright (c) 2014 Romain Derocle <rderocle@gmail.com>
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
# @copyright 2012-2013 Geoffroy Aubry <geoffroy.aubry@free.fr>
# @copyright 2014 Romain Derocle <rderocle@gmail.com>
# @license http://www.apache.org/licenses/LICENSE-2.0
#

BIN_DIR:="/usr/local/bin"
CURRENT_SHELL=$(shell if [ ! -z "$ZSH_NAME" ]; then echo "zsh"; else echo "bash"; fi)

.PHONY: all doc help install uninstall

default: help

doc:
	@$(CURRENT_SHELL) /home/romain/dev/twenga/twgit/makefile.sh doc

help:
	@$(CURRENT_SHELL) /home/romain/dev/twenga/twgit/makefile.sh help

install:
	@$(CURRENT_SHELL) /home/romain/dev/twenga/twgit/makefile.sh install

uninstall:
	@$(CURRENT_SHELL) /home/romain/dev/twenga/twgit/makefile.sh uninstall
