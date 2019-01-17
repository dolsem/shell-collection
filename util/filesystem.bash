###########################################################################
# Script Name	: filesystem.bash
# Description	: Filesystem-related Bash functions.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

export DOLSEM_SHELL_COLLECTION_HELPERS_FILESYSTEM=true

abspath() {
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}