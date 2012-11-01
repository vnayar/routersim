#!/bin/bash

files="\
  buffer.d \
  ipheader.d \
  net.d \
  ipnetport.d \
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