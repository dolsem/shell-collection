###########################################################################
# Script Name	: network.bash
# Requires    : os.bash
# Description	: Network-related Bash functions.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

export DOLSEM_SHELL_COLLECTION_HELPERS_NETWORK=true

if [[ $DOLSEM_SHELL_COLLECTION_HELPERS_OS != true ]]; then
  source $(dirname ${BASH_SOURCE[0]})/os.bash
fi

get_ip() {
  declare ip;
  if is_macos; then
    ip="$(ipconfig getifaddr en1)"
  else
    which ip 1>/dev/null
    if [ $? -eq 0 ]; then
      ip=`ip address | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tail -1`
    else
      ip=`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tail -1`
    fi
  fi
  echo $ip
}