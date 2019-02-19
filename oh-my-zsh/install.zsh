#!/usr/bin/env zsh
###########################################################################
# Script Name	: install.zsh
# Description	: Installs Oh My Zsh and its plugins.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: January 2019
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

OHMYZSH_DIR=${0:a:h}
PROJECT_DIR="${OHMYZSH_DIR}/.."
SCRIPT_URL="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh"

source ${PROJECT_DIR}/utils/string.bash
source ${PROJECT_DIR}/utils/term.bash

if [[ $1 == "--return-control" ]]; then
    ZSH_EXEC_ON_START=`escape_fslash "${PROJECT_DIR}/install.bash \"$2\" --installed-oh-my-zsh"`
else
    ZSH_EXEC_ON_START=`escape_fslash "${OHMYZSH_DIR}/install_plugins.zsh --check"`
fi

RUN_CMD="echo 'if [[ -n \$ZSH_EXEC_ON_START ]]; then eval \$ZSH_EXEC_ON_START; fi' >> ~\/.zshrc \&\& ZSH_EXEC_ON_START='$ZSH_EXEC_ON_START' env zsh -l"
sh -c "$(curl -fsSL $SCRIPT_URL | sed "s/env zsh -l/$RUN_CMD/g")" | dim
