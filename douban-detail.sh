#!/bin/bash
USER_PATH=~
SOURCE_FILE="$USER_PATH/.bash_profile"
if [[ -f $SOURCE_FILE ]]; then
	echo "source $SOURCE_FILE"
	source $SOURCE_FILE
fi
SOURCE_FILE="$USER_PATH/.profile"
if [[ -f $SOURCE_FILE ]]; then
	echo "source $SOURCE_FILE"
	source $SOURCE_FILE
fi
TASK_URL=$1
PARAMS="{\"retry\":{\"total\":10}}"
LEVEL=2
if [[ $# -gt 1 ]]; then
	PARAMS=$1
fi
if [[ $# -gt 2 ]]; then
	LEVEL=$3
fi
sh ./create_task.sh "douban-movie-detail" "$TASK_URL" "$PARAMS" "$LEVEL"