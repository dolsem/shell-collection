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

PROJECT_DIR=$(dirname $0)
HOME_DIR=$(realpath ~)

#------< Imports >------#
source "$PROJECT_DIR"/utils/os.bash
source "$PROJECT_DIR"/utils/term.bash
source "$PROJECT_DIR"/utils/prompt.bash

#------< Constants >------#
FUNCTIONS_DIR=${HOME_DIR}/.functions
SCRIPTS_DIR=${HOME_DIR}/.scripts

FUNCTIONS_OPTION="Install shell functions"
SCRIPTS_OPTION="Install scripts"
OHMYZSH_OPTION="Install Oh My Zsh"
OHMYZSH_PLUGINS_OPTION="Install Oh My Zsh plugins"
ALIASES_OPTION="Install aliases"
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

ensure_installed() {
  if ! command -v $1; then
    echo "$1 is not installed. Installing..."
    if is_macos; then
      brew install $1
    else
      sudo apt install $1
    fi
  fi
}

#------< Installation Targets >------#
install_scripts() {
  # Copy scripts
  mkdir -p $SCRIPTS_DIR
  cp -f "$PROJECT_DIR"/scripts/* $SCRIPTS_DIR

  # Add to path
  append_to_rc "export PATH=\$PATH:'$SCRIPTS_DIR'"

  # Create aliases
  for filepath in "$PROJECT_DIR"/scripts/*.bash; do
    filename=$(basename -- "$filepath")
    cmd_name=${filename%.*}
    append_to_rc "alias $cmd_name=$filename"
  done

  return $?
}

install_functions() {
  # gdiff requires colordiff on MacOS
  if is_macos && ! command -v colordiff 1>/dev/null 2>&1; then
    echo "==> Installing colordiff for gdiff..." | blue
    brew install colordiff | dim
  fi

  if [ ! $? -eq 0 ]; then
    exit $?;
  fi

  # Copy functions
  mkdir -p $FUNCTIONS_DIR
  cp -f "$PROJECT_DIR"/functions/* $FUNCTIONS_DIR

  # Create index for sourcing
  ls "$PROJECT_DIR"/functions | xargs printf "source ${FUNCTIONS_DIR}/%s\n" > ${FUNCTIONS_DIR}/index

  # Add to rc file
  SOURCE_CMD="source ${FUNCTIONS_DIR}/index"
  append_to_rc $SOURCE_CMD

  return $?
}

install_aliases() {
  aliases_filename=".aliases"

  prompt_with_default aliases_filename "Choose filename for aliases file to be created"
  ALIASES_PATH="$HOME_DIR/$aliases_filename"

  # Copy aliases
  cp -f "$PROJECT_DIR"/aliases/aliases "$ALIASES_PATH"

  # Add to rc file
  SOURCE_CMD="source '$ALIASES_PATH'"
  if ! append_to_rc "$SOURCE_CMD"; then
    return 1
  fi
}

set_env_vars() {
  MAKE_VIM_DEFAULT_OPTION="Make Vim default editor"

  envvars_filename=".envvars"

  prompt_with_default envvars_filename "Choose filename for environment variables file to be created"
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
if [[ -z $1 ]]; then
  echo "Please select what you would like to install. Use <Space> to select/unselect, <Enter> to submit."
  prompt_for_multiselect to_install \
    "$OHMYZSH_OPTION;$OHMYZSH_PLUGINS_OPTION;$SCRIPTS_OPTION;$FUNCTIONS_OPTION;$ALIASES_OPTION;$ENVVARS_OPTION" \
    "true;true;true;true;true;true"
else
  IFS=';' read -r -a to_install <<< "$1"
fi

if [[ $2 == "--installed-oh-my-zsh" ]]; then
  reset_color
  echo "Done." | green
fi

INSTALL_OHMYZSH=${to_install[0]}
INSTALL_OHMYZSH_PLUGINS=${to_install[1]}
INSTALL_SCRIPTS=${to_install[2]}
INSTALL_FUNCTIONS=${to_install[3]}
INSTALL_ALIASES=${to_install[4]}
INSTALL_ENVVARS=${to_install[5]}

if [[ $INSTALL_OHMYZSH == true  ]]; then
  echo "==> Installing Oh My Zsh..." | blue
  ensure_installed zsh
  to_install[0]=
  ${PROJECT_DIR}/oh-my-zsh/install.zsh --return-control $(IFS=';' ; echo "${to_install[*]}")
  exit 0
fi

if [[ $INSTALL_OHMYZSH_PLUGINS == true  ]]; then
  echo "==> Installing Oh My Zsh plugins..." | blue
  ${PROJECT_DIR}/oh-my-zsh/install_plugins.zsh --return-control
  ohmyzsh_plugins_status=$?
fi

if [[ $INSTALL_SCRIPTS == true  ]]; then
  echo "==> Adding scripts to the environment..." | blue
  install_scripts
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $INSTALL_FUNCTIONS == true  ]]; then
  echo "==> Adding shell functions to the environment..." | blue
  install_functions
  if [ $? -eq 0 ]; then
    echo "Done." | green
  fi
fi

if [[ $INSTALL_ALIASES == true  ]]; then
  echo "==> Installing aliases..." | blue
  install_aliases
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

if [[ $INSTALL_OHMYZSH_PLUGINS == true && ohmyzsh_plugins_status -eq 0 ]]; then
  exec env ZSH_EXEC_ON_START= zsh -l
fi
