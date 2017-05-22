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
nginx -p `pwd` -c conf/nginx.conf $@
