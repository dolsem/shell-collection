###########################################################################
# Script Name	: prompt.bash
# Description	: Bash functions for getting user input.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

#------< Helpers >------#
ESC=$( printf "\033")

cursor_blink_on()   { printf "$ESC[?25h"; }
cursor_blink_off()  { printf "$ESC[?25l"; }
cursor_to()         { printf "$ESC[$1;${2:-1}H"; }


get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
read_key()          {
  local key
  IFS= read -rsn1 key 2>/dev/null >&2
  if [[ $key = ""      ]]; then echo enter; fi;
  if [[ $key = $'\x20' ]]; then echo space; fi;
  if [[ $key = $'\x1b' ]]; then
    read -rsn2 key
    if [[ $key = [A ]]; then echo up;    fi;
    if [[ $key = [B ]]; then echo down;  fi;
  fi
}

#------< Prompt functions >------#
prompt_with_default() {
  local message=$2
  local default=$3
  read -e -p "${message}: " -i "$default" $1
}

prompt_for_bool() {
  local retvar=$1
  local message=$2
  declare result

  echo -n "${message} (y/n): "
  while [ -z ${result:+x} ]; do
    read -s -n 1 response
    if [[ $response =~ [yY] ]]; then
      result=true
    elif [[ $response =~ [nN] ]]; then
      result=false
    fi
  done
  echo $response
  eval $retvar="'$result'"
}

prompt_for_file() {
  local retvar=$1
  local message=$2
  local error_fmt_message=$3
  declare __path

  if [ -z "$message" ]; then
    message='Enter path to file'
  fi
  if [ -z "$error_fmt_message" ]; then
    error_fmt_message="File '"'"$__path"'"'"' does not exist.'
  fi

  while true; do
    read -e -p "${message}: " __path
    if [ -z "$__path" ]; then
      echo -ne '\033[1A'
      continue
    fi
    if [ -f "$__path" ]; then
      break
    else
      eval "echo \"$error_fmt_message\""
    fi
  done

  eval $retvar="'$(abspath "$__path")'"
}

# Based on https://unix.stackexchange.com/a/415155
prompt_for_option() {
  print_option()      { printf "   $1 "; }
  print_selected()    { printf "  $ESC[7m $1 $ESC[27m"; }

  # initially print empty new lines (scroll down if at bottom of screen)
  for opt; do printf "\n"; done

  # determine current screen position for overwriting the options
  local lastrow=`get_cursor_row`
  local startrow=$(($lastrow - $#))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local selected=0
  while true; do
    # print options by overwriting the last lines
    local idx=0
    for opt; do
      cursor_to $(($startrow + $idx))
      if [ $idx -eq $selected ]; then
          print_selected "$opt"
      else
          print_option "$opt"
      fi
      ((idx++))
    done

    # respond to pressed key
    case `read_key` in
      enter)  break;;
      up)     ((selected--));
              if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
      down)   ((selected++));
              if [ $selected -ge $# ]; then selected=0; fi;;
    esac
  done

  # cursor position back to normal
  cursor_to $lastrow
  printf "\n"
  cursor_blink_on

  return $selected
}

prompt_for_multiselect() {
  print_inactive()    { printf "$2   $1 "; }
  print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
  toggle_option()    {
    local arr_name=$1
    eval "local arr=(\"\${${arr_name}[@]}\")"
    local option=$2
    if [[ ${arr[option]} == true ]]; then
      arr[option]=
    else
      arr[option]=true
    fi
    eval $arr_name='("${arr[@]}")'
  }

  local retval=$1
  local options
  local defaults

  IFS=';' read -r -a options <<< "$2"
  if [[ -z $3 ]]; then
    defaults=()
  else
    IFS=';' read -r -a defaults <<< "$3"
  fi
  local selected=()

  for ((i=0; i<${#options[@]}; i++)); do
    selected+=("${defaults[i]}")
    printf "\n"
  done

  # determine current screen position for overwriting the options
  local lastrow=`get_cursor_row`
  local startrow=$(($lastrow - ${#options[@]}))

  # ensure cursor and input echoing back on upon a ctrl+c during read -s
  trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
  cursor_blink_off

  local active=0
  while true; do
    # print options by overwriting the last lines
    local idx=0
    for option in "${options[@]}"; do
      local prefix="[ ]"
      if [[ ${selected[idx]} == true ]]; then
        prefix="[x]"
      fi

      cursor_to $(($startrow + $idx))
      if [ $idx -eq $active ]; then
        print_active "$option" "$prefix"
      else
        print_inactive "$option" "$prefix"
      fi
      ((idx++))
      done

      # respond to pressed key
      case `read_key` in
        space)  toggle_option selected $active;;
        enter)  break;;
        up)     ((active--));
                if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
        down)   ((active++));
                #echo "$active ${#options[@]}"
                if [ $active -ge ${#options[@]} ]; then active=0; fi;;
      esac
  done

  # cursor position back to normal
  cursor_to $lastrow
  printf "\n"
  cursor_blink_on

  eval $retval='("${selected[@]}")'
}
