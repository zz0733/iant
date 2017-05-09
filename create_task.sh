#!/bin/bash
# source ~/.bash_profile
TYPE=""
if [[ $# -gt 0 ]]; then
	TYPE=$1
fi
URL=""
if [[ $# -gt 1 ]]; then
	URL=$2
fi
PARAMS="{}"
if [[ $# -gt 2 ]]; then
	PARAMS=$3
fi
LEVEL=0
if [[ $# -gt 3 ]]; then
	LEVEL=$4
fi

if [[ "X$PARAMS" == "X" ]]; then
	PARAMS="{}"
fi
TASK_BODY="[{
  \"url\": \"$URL\",
  \"type\": \"$TYPE\",
  \"params\": $PARAMS,
  \"level\": $LEVEL,
  \"status\": 0
}]"
echo "SNAP_SERVER[$SNAP_SERVER],TASK_BODY=$TASK_BODY"
curl -X POST "$SNAP_SERVER/api/task.json?method=insert" -d "$TASK_BODY"