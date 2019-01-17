###########################################################################
# Script Name	: validation.bash
# Description	: Bash functions for string validation.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

export DOLSEM_SHELL_COLLECTION_HELPERS_VALIDATION=true

is_valid_ip() {
  regexp='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'
  if [[ $1 =~ $regexp ]]; then
    return 0
  else
    return 1
  fi
}