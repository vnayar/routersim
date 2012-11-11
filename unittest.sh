#!/bin/bash

files="\
  ipaddress.d \
  ipheader.d \
  ipdatagram.d \
  udpheader.d \
  buffer.d \
  net.d \
  ipnetport.d \
  routernode.d \
  "


# Test listed files.
for file in $files ; do
    echo -n "Testing $file ... "
    cmd="rdmd --main -unittest $file"
    $($cmd 2>/dev/null)
    if test $? -eq "0" ; then
        echo "pass."
    else
        echo "failed."
        echo "Command was: $cmd"
        break
    fi
done