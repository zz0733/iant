# curl -X POST '127.0.0.1:8088/dao/task.es?method=index' -d '
# ["AVtxdPNMdTwFceDmuCpH"]
# '
# exit 0
# curl -X POST '127.0.0.1:8088/dao/task.es?method=load' -d '
# {"from":0,"size":10,"level":1}
# '

curl -X GET '127.0.0.1:8088/api/task.json?method=getmore'

# curl -X GET '127.0.0.1:8088/api/script.json?method=get&type=douban-movie-detail'