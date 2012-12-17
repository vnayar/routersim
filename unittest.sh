#!/bin/bash

files="\
  conv.d \
  ipaddress.d \
  ipheader.d \
  ipdatagram.d \
  udpheader.d \
  udpdatagram.d \
  tcpheader.d \
  tcpdatagram.d \
  buffer.d \
  net.d \
  ipnet.d \
  ipnetport.d \
  csvrouternode.d \
  ripmessage.d \
  riprouternode.d \
  "


# Test listed files.
for file in $files ; do
    echo -n "Testing $file ... "
    cmd="rdmd --main -w -debug -unittest $file"
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