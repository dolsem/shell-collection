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

relpath() {
  if command -v realpath 1>/dev/null; then
    realpath --relative-to="$1" "$2"
  else
    perl -MFile::Spec -e "print File::Spec->abs2rel(q($2),q($1))"
  fi
}

case $1 in
  s)
    exec "$git" status -s ${@:2}
  ;;
  dc)
    exec "$git" diff --cached "$2"
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

    if [[ -z $2 ]]; then
      if [[ ! -d "$retrospect_dir" ]]; then
        echo "No files are being retrospected"
      else
        printf "Files currently being retrospected:\n\n"
        cd "$retrospect_dir" && find * -type f
      fi
      exit
    fi

    dir=$(dirname "$2" 2>/dev/null)
    if [[ ! $? -eq 0 ]]; then
      echo "'$2' is not a valid path"
      exit 1
    fi
    if [[ -d "$2" ]]; then
      echo "git retrospect does not work with directories"
      exit 1
    fi

    relative_dir=$(relpath "$git_dir/.." "$dir")
    new_dir=$retrospect_dir
    if [[ "$relative_dir" == . ]]; then
      relative_dir=
      depth=1
    else
      new_dir="${new_dir}/${relative_dir}"
      depth=$(($(res="${relative_dir//[^\/]}"; echo ${#res})+2))
    fi

    mkdir -p "$new_dir"
    if [[ ! $? -eq 0 ]]; then
      exit $?
    fi

    filename=$(basename -- "$2")
    new_path="${new_dir}/${filename}"

    if [[ $3 == --abort ]]; then
      if [[ ! -f "$new_path" ]]; then
        echo "'$2' is not found in retrospect cache"
        exit 1
      fi
      mv "$new_path" "$2" && rmdir_recursive "$new_dir" $depth
      exit
    fi

    if [[ ! -f "$2" ]]; then
      echo "'$2' did not match any files"
      exit 1
    fi

    if grep -q "^<<<<<<<" "$2"; then
      echo "'$2' has unresolved conflicts that have to be resolved first"
      exit 1
    fi

    if [[ $3 == --done ]]; then
      "$git" add "$2" && mv "$new_path" "$2" && rmdir_recursive "$new_dir" $depth
      exit $?
    fi

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
    print_conflict_diff "$([[ -n $relative_dir ]] && echo "$relative_dir/")$filename" "$new_path" > "$2"
  ;;

  *)
    eval "exec $(printf "'%s' " "$git" "$@")"
  ;;
esac
