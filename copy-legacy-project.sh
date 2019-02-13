#!/bin/bash

SOURCE_FILE=$1
DESTINATION_PROJECT=$(pwd)/$2
HISTORY_FILE=./cache/history.list
SEARCH_FILE=./cache/search.list

# Initialize the project
if [ ! -e $DESTINATION_PROJECT ]; then
	mkdir $DESTINATION_PROJECT
fi

if [ ! -e './cache/' ]; then
	mkdir cache
fi

rm $HISTORY_FILE && touch $HISTORY_FILE
rm $SEARCH_FILE && touch $SEARCH_FILE

function copyAllDependencies() {
	RELDIR=`dirname $SOURCE_FILE`

	while read FILE; do
		# Make the necessary file structure
		FILE_DIR=`dirname $FILE`

		mkdir -p $DESTINATION_PROJECT$FILE_DIR
		cp $FILE $DESTINATION_PROJECT$FILE_DIR/
	done < $HISTORY_FILE
}

function sitesRemainToBeSearched() {
	CONTENTS=$(cat $SEARCH_FILE | wc -c)
	if [[ $CONTENTS -gt 2 ]]; then
		return 0
	else
		return 1
	fi
}

function realPath() {
	DIR=`dirname $1`
	REALPATH="`cd $DIR;pwd`"
	echo $REALPATH/$(basename $1)
}

function markAsSearched() {
	if [ $1 ]; then
		echo $1 >> $HISTORY_FILE
		echo "`cat $SEARCH_FILE | grep -vFx $1`" > $SEARCH_FILE
	fi
}

function findDependencies() {
	FOUND_LIST=./cache/found.list
	if [ ! -e $1 ]; then
		# markAsSearched $1
		return 1
	fi

	grep 'include(\|include_once(\|require(\|require_once(' $1 | grep -v '/\*' | grep -v 'require_once($\|require($\|include_once($\|include($' | sed -e "s/.*require('//g;s/.*require_once('//g;s/.*require(\"//g;s/.*require_once(\"//g;s/.*include('//g;s/.*include_once('//g;s/.*include(\"//g;s/.*include_once(\"//g;s/').*//g;s/\").*//g" | sort -u > $FOUND_LIST

	i=0

	while read FILE; do
		RELDIR=`dirname $1`
		REALPATH=$(realPath $RELDIR/$FILE)
    	i=$(expr $i + 1)

    	# If file hasn't been searched, add it to search list
    	if [ ! `grep -Fx $REALPATH $HISTORY_FILE` ]; then
    		if [ -e $REALPATH ]; then
    			echo $REALPATH >> $SEARCH_FILE
    		fi
    	fi
	done < $FOUND_LIST

	echo "$i dependencies found in $1"

	# Mark this file as searched and remove it from the search file
	markAsSearched $1
}

# Kick off the search by adding the specified file
echo $1 > $SEARCH_FILE

# While there are still things to check, look through them
while sitesRemainToBeSearched; do
	while read DEPENDENCY; do
		findDependencies $DEPENDENCY
	done < $SEARCH_FILE
done

copyAllDependencies
