#!/bin/bash

SOURCE_FILE=$1
DESTINATION_PROJECT=$(pwd)/$2

# Initialize the project
if [ ! -e $DESTINATION_PROJECT ]; then
	mkdir $DESTINATION_PROJECT
fi

if [ ! -e './cache/' ]; then
	mkdir cache
fi

function copyAllDependencies() {
	RELDIR=`dirname $SOURCE_FILE`

	while read FILE; do
		FILEDIR=`dirname $RELDIR/$FILE | sed -e 's/.*\.\.\///g'`
		mkdir -p $DESTINATION_PROJECT/$FILEDIR
		cp $RELDIR/$FILE $DESTINATION_PROJECT/$FILEDIR/
	done < $CACHE_FILE
}

function realPath() {
	DIR=`dirname $1`
	REALPATH="`cd $DIR;pwd`"
	echo $REALPATH/$(basename $1)
}

function findDependencies() {
	FOUND=`grep 'include(\|include_once(\|require(\|require_once(' $1 | grep -v '/\*' | grep -v 'require_once($\|require($\|include_once($\|include($' | sed -e "s/.*require('//g;s/.*require_once('//g;s/.*require(\"//g;s/.*require_once(\"//g;s/.*include('//g;s/.*include_once('//g;s/.*include(\"//g;s/.*include_once(\"//g;s/').*//g;s/\").*//g" | sort -u`

	for FILE in $FOUND; do
		RELDIR=`dirname $1`
		realPath $RELDIR/$FILE
	done
}

# Get the dependencies for the root file
DEPENDENCIES=`findDependencies $SOURCE_FILE`

echo $DEPENDENCIES > dependencies.list

for DEPENDENCY in $DEPENDENCIES; do
	findDependencies $DEPENDENCY >> dependencies.list
done

# Remove any duplicates
sort -u dependencies.list -o dependencies.list
# rm -r cache/