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
source "$PROJECT_DIR"/utils/os.bash
source "$PROJECT_DIR"/utils/term.bash
source "$PROJECT_DIR"/utils/prompt.bash

#------< Constants >------#
RC_FILE=$(cd ~; pwd -P)/.zshrc
PLUGINS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins

AUTOSUGGEST='zsh-autosuggestions'
SYNTAX='zsh-syntax-highlighting'
ZSHMARKS='zshmarks'
K='k'
AUTOENV='autoenv'
THEFUCK='thefuck'

AUTOSUGGEST_URL='https://github.com/zsh-users/zsh-autosuggestions'
SYNTAX_URL='https://github.com/zsh-users/zsh-syntax-highlighting'
ZSHMARKS_URL='https://github.com/jocelynmallon/zshmarks'
K_URL='https://github.com/supercrabtree/k'
AUTOENV_URL='https://github.com/zpm-zsh/autoenv'

AUTOSUGGEST_OPTION="Install $AUTOSUGGEST ($AUTOSUGGEST_URL)"
SYNTAX_OPTION="Install $SYNTAX ($SYNTAX_URL)"
ZSHMARKS_OPTION="Install $ZSHMARKS ($ZSHMARKS_URL)"
K_OPTION="Install $K ($K_URL)"
AUTOENV_OPTION="Install $AUTOENV ($AUTOENV_URL)"
THEFUCK_OPTION="Enable $THEFUCK"

#------< Helpers >------#
enable_plugin() {
  sed -i -- -e '/^plugins=(.*/{' -e '/[( ]$1/h;x;/^$/{' -e "x;s/)/ $1)/" -e '}' -e '}' $RC_FILE
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
  "$AUTOSUGGEST_OPTION;$SYNTAX_OPTION;$ZSHMARKS_OPTION;$K_OPTION;$AUTOENV_OPTION;$THEFUCK_OPTION" \
  "true;true;true;true;true;true"

INSTALL_AUTOSUGGEST=${to_install[1]}
INSTALL_SYNTAX=${to_install[2]}
INSTALL_ZSHMARKS=${to_install[3]}
INSTALL_K=${to_install[4]}
INSTALL_AUTOENV=${to_install[5]}
ENABLE_THEFUCK=${to_install[6]}

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

if [[ $INSTALL_AUTOENV == true ]]; then
  exit_code=0
  echo "==> Installing $AUTOENV..." | blue
  git clone $AUTOENV_URL "${PLUGINS_DIR}/$AUTOENV" | dim \
  && enable_plugin $AUTOENV
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $ENABLE_THEFUCK == true ]]; then
  exit_code=0
  echo "==> Enabling $THEFUCK..." | blue

  if is_macos; then
    brew install thefuck
  else
    if ! command -v pip3 1>/dev/null 2>&1; then
      sudo apt update && sudo apt install python3-dev python3-pip python3-setuptools
    fi
    sudo -H pip3 install thefuck
  fi

  enable_plugin $THEFUCK
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $1 != --return-control ]]; then
  exec env ZSH_EXEC_ON_START= zsh -l
fi

exit $exit_code