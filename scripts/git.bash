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

source_util() { source "$(dirname $0)/.bash-utils/$1.bash" 2>/dev/null || util=$1 source /dev/stdin <<<"$(curl -fsSL 'https://github.com/dolsem/shell-collection/raw/master/source_utils.bash')" 1>&2; }
source_util os
source_util prompt

git=$(which -a git | tail -1)

print_conflict_diff() {
  "$git" show "HEAD:$1" |
    diff - "$2" \
      --unchanged-group-format='%=' \
      --old-group-format="<<<<<<< Old%c'\\12'%<=======%c'\\12'>>>>>>> New%c'\\12'" \
      --new-group-format="<<<<<<< Old%c'\\12'=======%c'\\12'%>>>>>>>> New%c'\\12'" \
      --changed-group-format="<<<<<<< Old%c'\\12'%<=======%c'\\12'%>>>>>>>> New%c'\\12'"
}

rmdir_recursive() {
  cwd=$(pwd)
  iter=$2

  cd $1
  while (($iter > 0)); do
    dir=$(basename -- $(pwd))
    cd ..
    rmdir "$dir" 2>/dev/null
    if [[ ! $? -eq 0 ]]; then
      iter=0
    else
      ((iter--))
    fi
  done
}

case $1 in
  s)
    exec "$git" status -s ${@:2}
  ;;
  dc)
    exec "$git" diff --cached "${2:-.}"
  ;;
  rbi)
    exec "$git" rebase -i ${@:2}
  ;;
  rbc)
    exec "$git" rebase --continue ${@:2}
  ;;
  readd)
    exec "$git" add $("$git" diff --name-only --cached)
  ;;
  unstash)
    exec "$git" checkout stash@{0} -- "$2"
  ;;
  +x)
    exec "$git" update-index --chmod=+x ${@:2}
  ;;
  retrospect)
    git_dir=$(cd $("$git" rev-parse --git-dir); pwd -P)
    retrospect_dir="${git_dir}/retrospect"

    # list pending files: $ git retrospect
    if [[ -z $2 ]]; then
      if [[ ! -d "$retrospect_dir" ]]; then
        echo "No files are being retrospected"
      else
        printf "Files currently being retrospected:\n\n"
        cd "$retrospect_dir" && find * -type f
      fi
      exit
    fi

    # other commands: $ git retrospect <file> [--abort|--done]
    dir=$(dirname "$2" 2>/dev/null)
    if [[ ! $? -eq 0 ]]; then
      echo "'$2' is not a valid path"
      exit 1
    fi
    if [[ -d "$2" ]]; then
      echo "git retrospect does not work with directories"
      exit 1
    fi

    relative_dir=$(cd $dir && git rev-parse --show-prefix)
    if [[ -z $relative_dir ]]; then
      new_dir=$retrospect_dir
      depth=1
    else
      new_dir="${retrospect_dir}/${relative_dir}"
      depth=$(($(res="${relative_dir//[^\/]}"; echo ${#res})+1))
    fi

    mkdir -p "$new_dir"
    if [[ ! $? -eq 0 ]]; then
      exit $?
    fi

    filename=$(basename -- "$2")
    new_path="${new_dir}${filename}"

    # cancel and revert changes: $ git retrospect <file> --abort
    if [[ $3 == --abort ]]; then
      if [[ ! -f "$new_path" ]]; then
        echo "'$2' is not found in retrospect cache"
        exit 1
      fi
      mv "$new_path" "$2" && rmdir_recursive "$new_dir" $depth
      exit
    fi

    # other commands: $ git retropect <file> [--done]
    if [[ ! -f "$2" ]]; then
      echo "'$2' did not match any files"
      exit 1
    fi

    if grep -q "^<<<<<<<" "$2"; then
      echo "'$2' has unresolved conflicts that have to be resolved first"
      exit 1
    fi

    # add selected changes to commit and restore file: $ git retrospect <file> --done
    if [[ $3 == --done ]]; then
      "$git" add "$2" && mv "$new_path" "$2" && rmdir_recursive "$new_dir" $depth
      exit $?
    fi

    # start retrospection: $ git retrospect <file>
    if command "$git" diff --quiet "$2"; then
      echo "'$2' has no unstaged changes"
      exit 1
    fi

    if [[ -f "$new_path" ]]; then
      prompt_for_bool overwrite "Overwrite ${filename} in retrospect cache (all changes will be lost)?"
      if [[ $overwrite == false ]]; then
        exit
      fi
    fi

    cp "$2" "$new_path"
    print_conflict_diff "${relative_dir}${filename}" "$new_path" > "$2"
  ;;

  *)
    eval "exec $(printf "'%s' " "$git" "$@")"
  ;;
esac
