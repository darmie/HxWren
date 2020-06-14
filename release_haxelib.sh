#!/bin/sh
rm -f WrenVM.zip
zip -r WrenVM.zip src *.hxml *.json *.md run.n
haxelib submit WrenVM.zip $HAXELIB_PWD --always