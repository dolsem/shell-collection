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

#------< Constants >------#
PREFIX='[Dolsem Bash Utils]'
REPO_URL='https://github.com/dolsem/bash-utils'
BASE_URL="${REPO_URL}/raw/master"
CACHE_DIR="$(realpath $(dirname ${BASH_SOURCE[1]}))/.bash-utils"

#------< Dependency graph (tree) >------#
deps_assert=()
deps_filesystem=()
deps_network=(os)
deps_os=()
deps_prompt=(filesystem assert)
deps_string=(os)
deps_term=()
deps_validation=()

#------< Helpers >------#
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

get_one() {
  mkdir -p "$CACHE_DIR"
  if cd "$CACHE_DIR"; then
    if [[ ! -f $1.bash ]]; then
      echo "${PREFIX} Getting $1 utilities..."
      if [[ -z $noprogress ]]; then
        wget -O "$1.bash" "${BASE_URL}/$1.bash" -q --show-progress --progress=bar:noscroll
      else
        wget -O "$1.bash" "${BASE_URL}/$1.bash" -q
      fi
    fi
    cd - 1>/dev/null
  else
    echo
    echo "${PREFIX} $CACHE_DIR: access denied"
    exit 1
  fi
  if [[ ! $? -eq 0 ]]; then
    exit $?
  fi
  echo -e '\033[1A\033[52C Done.'
}

get_dependencies() {
  eval "local deps=(\${deps_$1[@]})"
  if [ ! ${#deps[@]} -eq 0 ]; then
    echo "${PREFIX} Getting $1 utilities dependencies..."
    for dep_util in "${deps[@]}"; do
      get_one $dep_util
    done
  fi
}

#------< Main >------#
if [[ -z $util ]]; then
  clone_repo
  source "${CACHE_DIR}/*.bash"
else
  get_one $util
  get_dependencies $util
  source "${CACHE_DIR}/${util}.bash"
fi
