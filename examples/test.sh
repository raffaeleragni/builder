#!/usr/bin/env bash
set -e

for i in `ls`; do
  if [ -d $i ]; then
    cd $i;
    ../../types/jvm/build.sh
    cd -;
  fi
done

