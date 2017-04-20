# curl -X POST '127.0.0.1:8088/api/task.json?method=insert' -d '
#  [{
#   "type": "type",
#   "url": "url",
#   "params": "{}",
#   "level": 0,
#   "status": 0
# }]
# '
# exit 0
curl -X POST '127.0.0.1:8088/api/collect.json?method=insert' -d '
 [{
  "task": {"id":"az100","type": "type","url": "url","params": "{\"a\":123}"},
  "data": "content in content",
  "status": 1
}]
'