#!/bin/sh
# package script -- for macOS only

BIN_NAME=crocket_example
OUTZIP="${BIN_NAME}.zip"

shards build -Dsync_player || exit $?

rm -rf "./dist"
mkdir -p "./dist/$BIN_NAME/"
cp -v "./bin/${BIN_NAME}" "./dist/$BIN_NAME/${BIN_NAME}"

LIBS=`otool -L "./bin/${BIN_NAME}" | grep -v "./bin/${BIN_NAME}" | grep -v "/usr/lib" | awk '{ print $1; }' | xargs`
cp -v $LIBS "./dist/$BIN_NAME"

(cd dist && zip "crocket_example.zip" ./crocket_example/*)

rm -rf "./dist/$BIN_NAME"

