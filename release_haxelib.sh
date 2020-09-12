#!/bin/sh
rm -f wrenc.zip
zip -r wrenc.zip src *.hxml *.json *.md run.n
haxelib submit wrenc.zip $HAXELIB_PWD --always