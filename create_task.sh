#!/bin/bash
source ~/.bash_profile
# curl -X POST '127.0.0.1:8088/api/task.json?method=insert' -d '
#  [{
#   "type": "douban-movie-link",
#   "url": "https://movie.douban.com/tag/2000",
#   "params": {"a":100},
#   "level": 0,
#   "status": 0
# }]
# '
# exit 0
# curl -X POST '127.0.0.1:8088/api/collect.json?method=insert' -d '
#  [{
#   "task": {"id":"az100","type": "type","url": "url","params": "{\"a\":123}"},
#   "data": "content in content",
#   "status": 1
# }]
# '

# curl -X POST '127.0.0.1:8088/snap/data' -d '
#  [{
#   "task": {"id":"123","type": "type","url": "url","params": "{\"a\":123}"},
#   "data": "content in content",
#   "status": 1
# }]
# '

# curl -X POST '127.0.0.1:8088/api/task.json?method=insert' -d '
#  [{
#   "type": "douban-movie-link",
#   "url": "https://movie.douban.com/tag/1988",
#   "params": {"a":100},
#   "level": 1,
#   "status": 0
# }]
# '

# curl -X POST '127.0.0.1:8088/api/task.json?method=insert' -d '
#  [{
#   "type": "bdp-share",
#   "params": {"uk":3398440525,"retry":1},
#   "level": 1,
#   "status": 0
# }]
# '
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