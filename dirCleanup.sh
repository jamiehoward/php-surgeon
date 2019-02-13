#! /bin/bash
STARTING_DIR=$1
ROOT_DIR=''

cd $STARTING_DIR

checkDir() {
	COUNT=$(find $1 -not -path '*/\.*' -type d -d 1 | wc -l)

	if [ $COUNT -gt 1 ]; then
		ROOT_DIR=$1
		return 0
	fi

	for FILE in $1/*; do
		if [ -d $FILE ]; then
			checkDir $FILE
		elif [ -e $FILE ]; then
			ROOT_DIR=$1
			return 0
		fi
	done
}

checkDir $STARTING_DIR

echo $ROOT_DIR
