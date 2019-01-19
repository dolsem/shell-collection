#!/bin/bash
###########################################################################
# Script Name	: install.bash
# Description	: Adds shell functions to the environment.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

#------< Imports >------#
source ./utils/os.bash
source ./utils/term.bash
source ./utils/prompt.bash

#------< Constants >------#
HOME_DIR=$(realpath ~)
FUNCTIONS_DIR=${HOME_DIR}/.functions

FUNCTIONS_OPTION="Install shell functions"
OHMYZSH_OPTION="Install Oh My Zsh"

#------< Installation Targets >------#
install_functions() {
  # Install colordiff
  if ! command -v colordiff 1>/dev/null 2>&1; then
    echo "==> Installing colordiff for gdiff..." | blue
    if is_macos; then
      brew install colordiff | dim
    else
      sudo apt install colordiff | dim
    fi
  fi

  if [ ! $? -eq 0 ]; then
    exit $?;
  fi

  # Copy functions
  mkdir -p $FUNCTIONS_DIR
  cp -f ./functions/* $FUNCTIONS_DIR
  # Create index for sourcing
  ls ./functions | xargs printf "source ${FUNCTIONS_DIR}/%s\n" > ${FUNCTIONS_DIR}/index
  # Add to rc file
  SOURCE_CMD="source ${FUNCTIONS_DIR}/index"
  if [ -e ~/.bashrc ]; then
    if [[ -z $(grep "$SOURCE_CMD" ~/.bashrc) ]]; then
      echo "$SOURCE_CMD" >> ~/.bashrc
    fi
    CMD_ADDED=true
  else
    if [ -e ~/.bash_profile ]; then
      if [[ -z $(grep "$SOURCE_CMD" ~/.bash_profile) ]]; then
        echo "$SOURCE_CMD" >> ~/.bash_profile
      fi
      CMD_ADDED=true
    fi
  fi

  if [ -e ~/.zshrc ]; then
    if [[ -z $(grep "$SOURCE_CMD" ~/.zshrc) ]]; then
      echo "$SOURCE_CMD" >> ~/.zshrc
    fi
    CMD_ADDED=true
  fi

  if [[ $CMD_ADDED != true ]]; then
    echo "Error: could not find an rc file." | red
    return 1
  fi
}

install_oh_my_zsh() {
  SCRIPT_URL="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
  ZSH_EXEC_ON_START=".\/install.bash \"$1\" --installed-oh-my-zsh"
  RUN_CMD="echo 'if [[ -n \$ZSH_EXEC_ON_START ]]; then eval \$ZSH_EXEC_ON_START; fi' >> ~\/.zshrc \&\& ZSH_EXEC_ON_START='$ZSH_EXEC_ON_START' env zsh -l"

  sh -c "$(curl -fsSL $SCRIPT_URL | sed "s/env zsh -l/$RUN_CMD/g")" | dim
}

#------< Main >------#

if [[ $2 == "--installed-oh-my-zsh" ]]; then
  reset_color
  echo "Done." | green
fi

if [[ -z $1 ]]; then
  echo "Please select what you would like to install. Use <Space> to select/unselect, <Enter> to submit."
  prompt_for_multiselect to_install "$OHMYZSH_OPTION;$FUNCTIONS_OPTION" "true;true"
else
  IFS=';' read -r -a to_install <<< "$1"
fi

INSTALL_OHMYZSH=${to_install[0]}
INSTALL_FUNCTIONS=${to_install[1]}

if [[ $INSTALL_OHMYZSH == true  ]]; then
  echo "==> Installing Oh-My-Zsh..." | blue
  to_install[0]=
  install_oh_my_zsh $(IFS=';' ; echo "${to_install[*]}")
  exit 0
fi

if [[ $INSTALL_FUNCTIONS == true  ]]; then
  echo "==> Adding shell functions to the environment..." | blue
  install_functions
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

