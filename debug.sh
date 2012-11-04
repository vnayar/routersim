#!/bin/bash

if [[ "$1" == "" || "$2" != "" ]]; then
   echo "usage: $0 <executable>"
   exit
fi

"$1" | grep -Po "0x[\d\w]+" | /usr/bin/addr2line -e "$1" | grep -v "^??" | sed -r 's/(.*):([0-9]*)/printf "\\033[0;31m\0:\\033[0m\n    " \&\& sed -n \2p \1 | sed "s\/^ *\/\/"/' | bash