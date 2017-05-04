#!/bin/bash
FILE_PATH="/apps/src/codes/bdcodes/snapper/snapper-client/script/douban-movie-detail.js"
if [[ $# -gt 0 ]]; then
	FILE_PATH=$1
fi
echo "[`date`] upload file:$FILE_PATH"
curl -X POST '127.0.0.1:8088/api/script.json?method=insert' \
-F "filename=@$FILE_PATH;type=application/octet-stream"
