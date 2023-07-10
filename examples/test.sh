#!/usr/bin/env bash

set -e

CURDIR=$(cd `dirname $BASH_SOURCE` && pwd)

for i in `ls`; do
  if [ -d $i ]; then
    cd $i;
    $CURDIR/../build.sh
    cd -;
  fi
done

