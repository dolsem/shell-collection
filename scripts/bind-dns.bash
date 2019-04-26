#!/usr/bin/env bash
###########################################################################
# Script Name : bind-dns.sh
# Description : script to start and stop bind DNS server.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: March 2019
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

source_util() { source "$(dirname $0)/.bash-utils/$1.bash" 2>/dev/null || util=$1 source <(curl -fsSL 'https://github.com/dolsem/shell-collection/raw/master/source_utils.bash') 1>&2; }
source_util prompt

IMAGE_NAME=sameersbn/bind
CONTAINER_NAME=bind-dns
password=SecretPassword

if ! command -v docker 1>/dev/null 2>&1; then
  echo 'Docker must be in your PATH'
  exit 1
fi

run_container() {
  IFS=$'\n' read -d '' -r -a ip_addrs <<< $(ip -o -4 addr show | sed -n 's#.* inet \(.*\)/.*#\1#p')
  echo 'Choose IP address to use:'
  prompt_for_option ${ip_addrs[@]}
  ip=${ip_addrs[$?]}
  prompt_with_default password 'Choose password: '
  docker run -d \
      -p $ip:53:53/udp \
      -p $ip:53:53/tcp \
      -p 10000:10000/tcp \
      -v /srv/docker/bind:/data \
      -e ROOT_PASSWORD=$password \
      --dns=127.0.0.1 \
      --name $CONTAINER_NAME \
      $IMAGE_NAME \
      > /dev/null
}

case $1 in
  start)
    if docker container inspect $CONTAINER_NAME 1>/dev/null 2>&1; then
      docker start $CONTAINER_NAME > /dev/null
    else
      run_container
    fi
    if [[ $? -eq 0 ]]; then
      echo "Success! You can visit Web GUI at https://localhost:10000 (use 'root' as username)"
    fi
  ;;

  stop)
    docker stop $CONTAINER_NAME 1>/dev/null && echo 'Stopped.'
  ;;

  reset)
    docker rm -f $CONTAINER_NAME 1>/dev/null 2>/dev/null
    run_container
  ;;

  status)
    docker container inspect $CONTAINER_NAME
  ;;

  *)
    echo 'Usage: bind-dns start|stop|reset|status'
    exit 1
  ;;
esac
