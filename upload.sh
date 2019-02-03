#!/bin/bash
FILE_PATH="/apps/src/codes/bdcodes/snapper/snapper-client/script/douban-movie-detail.js"
if [[ $# -gt 0 ]]; then
	FILE_PATH=$1
fi
echo "[`date`] upload file:$FILE_PATH"
echo "[`date`] curl -X POST $SNAP_SERVER/api/script.json?method=insert"
curl -s -X POST "$SNAP_SERVER/api/script.json?method=insert" \
-F "filename=@$FILE_PATH;type=application/octet-stream"
