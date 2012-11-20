#!/bin/bash

files="\
  csv_demo.d \
  rip_demo.d \
  "

# Build listed programs.
for file in $files ; do
  echo -n "Building $file ... "
  cmd="rdmd --build-only -w $file"
  $($cmd &> build.log)
  if test $? -eq "0" ; then
      echo "done."
  else
      echo "failed."
      echo "Command was: $cmd"
      cat build.log
      break
  fi
done