#!/bin/bash

files="\
  buffer.d \
  ipheader.d \
  "


# Test listed files.
for file in $files ; do
    echo -n "Testing $file ... "
    rdmd --main -unittest $file 2>/dev/null
    if test $? -eq "0" ; then echo "pass." ; else echo "fail." ; fi
done