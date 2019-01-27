#!/usr/bin/env bash
###########################################################################
# Script Name	: git.bash
# Description	: git wrapper with a few useful commands
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

source_util() { source "$(dirname $0)/.bash-utils/$1.bash" 2>/dev/null || util=$1 source <(curl -fsSL 'https://github.com/dolsem/shell-collection/raw/master/source_utils.bash') 1>&2; }
source_util os
source_util prompt

case $1 in
  s)
    exec git status -s
  ;;
  dc)
    exec git diff --cached "$2"
  ;;
  readd)
    exec git add $(git diff --name-only --cached)
  ;;
  unstash)
    exec git checkout stash@{0} -- "$2"
  ;;
  retrospect)
    if [[ ! -f "$2" ]]; then
      echo "'$2' did not match any files"
      exit 1
    fi

    filename=$(basename -- "$2")
    extension=$([[ "$filename" = *.* ]] && echo ".${filename##*.}")
    basepath=$([[ -n $extension ]] && echo "${2%.*}" || echo $2)
    new_path="${basepath}.new${extension}"

    if [[ $3 == --done ]]; then
      if ! command git diff --quiet "$2"; then
        prompt_for_bool overwrite "'$2' contains unstaged changes. Overwrite?"
        if [[ $overwrite == false ]]; then
          exit
        fi
      fi
      mv "$new_path" "$2"
      exit $?
    else
      if [[ $3 != --continue ]]; then
        if [[ -f "$new_path" ]]; then
          prompt_for_bool overwrite "Overwrite ${new_path}?"
          if [[ $overwrite == false ]]; then
            exit
          fi
        fi

        mv "$2" "$new_path"
        command git checkout -- "$2"
      fi
    fi

    if is_macos; then
      if command -v colordiff 1>/dev/null 2>&1; then
        exec colordiff -u "$2" "$new_path" | less -r
      else
        exec diff -u "$2" "$new_path" | less -r
      fi
    else
      exec diff -u --color=always "$2" "$new_path" | less -r
    fi
  ;;

  *)
    eval "exec $(printf "'%s' " git "$@")"
  ;;
esac
