###########################################################################
# Script Name	: string.bash
# Requires    : os.bash
# Description	: Bash functions for string manipulation.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

export DOLSEM_SHELL_COLLECTION_HELPERS_STRING=true

if [[ $DOLSEM_SHELL_COLLECTION_HELPERS_OS != true ]]; then
  source $(dirname ${BASH_SOURCE[0]})/os.bash
fi

strip_whitespace() {
  regexp="((\S+\s+)*\S+)"
  if is_macos; then
    echo $1 | perl -nle"if (m{$regexp}g) { print \$1; }"
  else
    echo $1 | grep -oP $regexp
  fi
}