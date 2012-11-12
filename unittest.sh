#!/bin/bash

files="\
  ipaddress.d \
  ipheader.d \
  udpheader.d \
  ipdatagram.d \
  udpdatagram.d \
  buffer.d \
  net.d \
  ipnetport.d \
  routernode.d \
  "


# Test listed files.
for file in $files ; do
    echo -n "Testing $file ... "
    cmd="rdmd --main -w -unittest $file"
    $($cmd &> unittest.log)
    if test $? -eq "0" ; then
        echo "pass."
    else
        echo "failed."
        echo "Command was: $cmd"
        cat unittest.log
        break
    fi
done