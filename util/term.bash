###########################################################################
# Script Name	: term.bash
# Description	: Terminal-related Bash functions.
# Author      : Denis Semenenko
# Email       : dols3m@gmail.com
# Date written: September 2018
#
# Distributed under MIT license
# Copyright (c) 2019 Denis Semenenko
###########################################################################

red() { tput setaf 1; cat; tput sgr0; }
green() { tput setaf 2; cat; tput sgr0; }
yellow() { tput setaf 3; cat; tput sgr0; }
blue() { tput setaf 4; cat; tput sgr0; }
magenta() { tput setaf 5; cat; tput sgr0; }
cyan() { tput setaf 6; cat; tput sgr0; }
white() { tput setaf 7; cat; tput sgr0; }
dim() { tput dim; cat; tput sgr0; }