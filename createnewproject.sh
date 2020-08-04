#!/bin/bash

echo `dirname $0`;
SCRIPT_DIR=`dirname $0`
NEW_PROJECT_DIR=$SCRIPT_DIR/$1;
if [ -e $NEW_PROJECT_DIR ]; then
    exit 1;
fi
mkdir $NEW_PROJECT_DIR
cp $SCRIPT_DIR/MakefileTemplate $NEW_PROJECT_DIR/Makefile
cp pot12_final.ptau $NEW_PROJECT_DIR

