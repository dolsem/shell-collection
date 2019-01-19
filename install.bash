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
ENVVARS_OPTION="Set additional environment variables"

#------< Helpers >------#
append_once() {
  local line="$1"
  local filepath="$2"
  if [[ -z $(grep "$line" "$filepath") ]]; then
    echo "$line" >> "$filepath"
  fi
}

append_to_rc() {
  CMD="$1"

  if [ -e ~/.bashrc ]; then
    append_once "$CMD" ~/.bashrc
    CMD_ADDED=true
  else
    if [ -e ~/.bash_profile ]; then
      append_once "$CMD" ~/.bash_profile
      CMD_ADDED=true
    fi
  fi

  if [ -e ~/.zshrc ]; then
    append_once "$CMD" ~/.zshrc
    CMD_ADDED=true
  fi

  if [[ $CMD_ADDED != true ]]; then
    echo "Error: could not find an rc file." | red
    return 1
  fi
}

make_vim_default() {
  ENVVARS_PATH="$1"
  append_once "export VISUAL=vim" "$ENVVARS_PATH"
  append_once 'export EDITOR="$VISUAL"' "$ENVVARS_PATH"
}

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
  append_to_rc $SOURCE_CMD

  return $?
}

install_oh_my_zsh() {
  SCRIPT_URL="https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
  ZSH_EXEC_ON_START=".\/install.bash \"$1\" --installed-oh-my-zsh"
  RUN_CMD="echo 'if [[ -n \$ZSH_EXEC_ON_START ]]; then eval \$ZSH_EXEC_ON_START; fi' >> ~\/.zshrc \&\& ZSH_EXEC_ON_START='$ZSH_EXEC_ON_START' env zsh -l"

  sh -c "$(curl -fsSL $SCRIPT_URL | sed "s/env zsh -l/$RUN_CMD/g")" | dim
}

set_env_vars() {
  ENVVARS_FILENAME_DEFAULT=".envvars"

  MAKE_VIM_DEFAULT_OPTION="Make Vim default editor"

  prompt_with_default envvars_filename "Choose filename for environment variables file to be created" $ENVVARS_FILENAME_DEFAULT
  ENVVARS_PATH="$HOME_DIR/$envvars_filename"

  # Add to rc file
  touch "$ENVVARS_PATH"
  SOURCE_CMD="source '$ENVVARS_PATH'"
  if ! append_to_rc "$SOURCE_CMD"; then
    return 1
  fi

  echo "Please select what you would like to set. Use <Space> to select/unselect, <Enter> to submit."
  prompt_for_multiselect vars_to_set "$MAKE_VIM_DEFAULT_OPTION"

  MAKE_VIM_DEFAULT=${vars_to_set[0]}

  if [[ $MAKE_VIM_DEFAULT == true ]]; then
    make_vim_default $ENVVARS_PATH
  fi
}

#------< Main >------#
if [[ $2 == "--installed-oh-my-zsh" ]]; then
  reset_color
  echo "Done." | green
fi

if [[ -z $1 ]]; then
  echo "Please select what you would like to install. Use <Space> to select/unselect, <Enter> to submit."
  prompt_for_multiselect to_install "$OHMYZSH_OPTION;$FUNCTIONS_OPTION;$ENVVARS_OPTION" "true;true;true"
else
  IFS=';' read -r -a to_install <<< "$1"
fi

INSTALL_OHMYZSH=${to_install[0]}
INSTALL_FUNCTIONS=${to_install[1]}
INSTALL_ENVVARS=${to_install[2]}

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

if [[ $INSTALL_ENVVARS == true  ]]; then
  echo "==> Setting environment variables..." | blue
  set_env_vars
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi
