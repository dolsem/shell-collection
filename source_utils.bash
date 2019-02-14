#!/bin/bash
###########################################################################
# Script Name	: source_utils.bash
# Description	: Used to store local copy of utils for sourcing.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

PREFIX='[Dolsem Bash Utils]'
REPO_URL='https://github.com/dolsem/bash-utils'
BASE_URL="${REPO_URL}/raw/master"
CACHE_DIR="$(dirname $0)/.bash-utils"

clone_repo() {
  echo "${PREFIX} Getting all utilities..."
  if [[ -z $noprogress ]]; then
    git clone $REPO_URL "${CACHE_DIR}"
  else
    git clone $REPO_URL "${CACHE_DIR}" 1>/dev/null
  fi    
  if [[ ! $? -eq 0 ]]; then
    exit $?
  fi
}

download_one() {
  echo "${PREFIX} Getting $1 utilities..."
  mkdir -p "$CACHE_DIR"
  if cd "$CACHE_DIR"; then
    if [[ -z $noprogress ]]; then
      wget -O "$1.bash" "${BASE_URL}/$1.bash" -q --show-progress --progress=bar:noscroll
    else
      wget -O "$1.bash" "${BASE_URL}/$1.bash" -q
    fi
    cd - 1>/dev/null
  fi
  if [[ ! $? -eq 0 ]]; then
    exit $?
  fi
}

if [[ -z $util ]]; then
  clone_repo
  source "${CACHE_DIR}/*.bash"
else
  download_one $util
  source "${CACHE_DIR}/${util}.bash"
fi

if [[ $? -eq 0 ]]; then
  echo "${PREFIX} Done."
else
  exit $?
fi