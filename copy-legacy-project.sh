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
	normalDir="`cd $DIR;pwd`"
	echo $normalDir/$(basename $1)
}

DEPENDENCIES='dependencies.list'
rm $DEPENDENCIES

function findDependencies() {
	CACHE_FILE=./cache/files.cache

	rm $CACHE_FILE

	grep 'include(\|include_once(\|require(\|require_once(' $1 | grep -v '/\*' | grep -v 'require_once($\|require($\|include_once($\|include($' > $CACHE_FILE

	# Remove requires
	sed -i -e "s/.*require('//g;s/.*require_once('//g;s/.*require(\"//g;s/.*require_once(\"//g;
		" $CACHE_FILE

	# Remove includes
	sed -i -e "s/.*include('//g;s/.*include_once('//g;s/.*include(\"//g;s/.*include_once(\"//g;
		" $CACHE_FILE

	# Remove trailing parentheses
	sed -i -e "s/').*//g;s/\").*//g" $CACHE_FILE

	# Prepend the directory
	RELDIR=`dirname $1`

	while read FILE;do
		realPath $RELDIR/$FILE >> $DEPENDENCIES
	done < $CACHE_FILE
}

# Get the dependencies for the root file
findDependencies $SOURCE_FILE

while read FILE; do
	findDependencies $FILE
done < $DEPENDENCIES

# Remove any duplicates
sort -u $DEPENDENCIES -o $DEPENDENCIES
# rm -r cache/