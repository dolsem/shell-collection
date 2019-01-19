#!/usr/bin/env bash
###########################################################################
# Script Name	: install.sh
# Description	: Adds shell functions to the environment.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

HOME_DIR=$(realpath ~)
FUNCTIONS_DIR=${HOME_DIR}/.functions

source ./utils/os.bash
source ./utils/term.bash

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

echo "==> Adding shell functions to the environment..." | blue
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
  exit 1
fi
echo "Done." | green
