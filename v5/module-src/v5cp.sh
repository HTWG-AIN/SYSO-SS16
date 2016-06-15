#!/bin/bash

MODULE_SRC=${1-.}
DEST=$TARGET/buildroot/dl

prev_dir=$(pwd)
cd $MODULE_SRC
for d in */; do
    echo -n "## Preparing ${d%%/} Buildroot module... "
    tar czf $DEST/${d%%/}.tar.gz $d
    echo "done"
done
cd $prev_dir
