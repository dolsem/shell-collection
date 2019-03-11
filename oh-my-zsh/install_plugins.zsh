#!/usr/bin/env zsh
###########################################################################
# Script Name	: install_plugins.zsh
# Description	: Installs Oh My Zsh plugins.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: January 2019
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

OHMYZSH_DIR=${0:a:h}
PROJECT_DIR="${OHMYZSH_DIR}/.."

#------< Imports >------#
source "$PROJECT_DIR"/utils/term.bash
source "$PROJECT_DIR"/utils/prompt.bash

#------< Constants >------#
RC_FILE=$(cd ~; pwd -P)/.zshrc
PLUGINS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins

AUTOSUGGEST='zsh-autosuggestions'
SYNTAX='zsh-syntax-highlighting'
ZSHMARKS='zshmarks'
K='k'

AUTOSUGGEST_URL='https://github.com/zsh-users/zsh-autosuggestions'
SYNTAX_URL='https://github.com/zsh-users/zsh-syntax-highlighting'
ZSHMARKS_URL='https://github.com/jocelynmallon/zshmarks'
K_URL='https://github.com/supercrabtree/k'

AUTOSUGGEST_OPTION="Install $AUTOSUGGEST ($AUTOSUGGEST_URL)"
SYNTAX_OPTION="Install $SYNTAX ($SYNTAX_URL)"
ZSHMARKS_OPTION="Install $ZSHMARKS ($ZSHMARKS_URL)"
K_OPTION="Install $K ($K_URL)"

#------< Helpers >------#
enable_plugin() {
  sed -i -- "/^plugins=(.*/{/[( ]$1/h;x;/^$/{x;s/)/ $1)/}}" $RC_FILE
}

#------< Installation Targets >------#

#------< Main >------#
reset_color

if [[ $1 == --check ]]; then
  prompt_for_bool proceed "Install Oh My Zsh plugins?"
  if [[ $proceed != true ]]; then
    exit
  fi
fi

echo "Please select what plugins you would like to install. Use <Space> to select/unselect, <Enter> to submit."
prompt_for_multiselect to_install \
  "$AUTOSUGGEST_OPTION;$SYNTAX_OPTION;$ZSHMARKS_OPTION;$K_OPTION" \
  "true;true;true;true"

INSTALL_AUTOSUGGEST=${to_install[1]}
INSTALL_SYNTAX=${to_install[2]}
INSTALL_ZSHMARKS=${to_install[3]}
INSTALL_K=${to_install[4]}

exit_code=1

if [[ $INSTALL_AUTOSUGGEST == true ]]; then
  exit_code=0
  echo "==> Installing $AUTOSUGGEST..." | blue
  git clone $AUTOSUGGEST_URL "${PLUGINS_DIR}/$AUTOSUGGEST" | dim \
  && enable_plugin $AUTOSUGGEST
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $INSTALL_SYNTAX == true ]]; then
  exit_code=0
  echo "==> Installing $SYNTAX..." | blue
  git clone $SYNTAX_URL "${PLUGINS_DIR}/$SYNTAX" | dim \
  && enable_plugin $SYNTAX
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $INSTALL_ZSHMARKS == true ]]; then
  exit_code=0
  echo "==> Installing $ZSHMARKS..." | blue
  git clone $ZSHMARKS_URL "${PLUGINS_DIR}/$ZSHMARKS" | dim \
  && enable_plugin $ZSHMARKS
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $INSTALL_K == true ]]; then
  exit_code=0
  echo "==> Installing $K..." | blue
  git clone $K_URL "${PLUGINS_DIR}/$K" | dim \
  && enable_plugin $K
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $1 != --return-control ]]; then
  exec env ZSH_EXEC_ON_START= zsh -l
fi

exit $exit_code
