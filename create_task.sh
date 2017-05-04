#!/bin/bash

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
PARAMS="{}"
if [[ $# -gt 1 ]]; then
	PARAMS=$2
fi
LEVEL=0
if [[ $# -gt 2 ]]; then
	LEVEL=$3
fi
echo "TYPE=$TYPE,PARAMS=$PARAMS,LEVEL=$LEVEL"
curl -X POST '127.0.0.1:8088/api/task.json?method=insert' -d "
 [{
  \"type\": \"$TYPE\",
  \"params\": $PARAMS,
  \"level\": $LEVEL,
  \"status\": 0
}]
"