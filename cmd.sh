# curl -X POST '127.0.0.1:8088/dao/task.es?method=index' -d '
# ["AVtxdPNMdTwFceDmuCpH"]
# '
# exit 0
# curl -X POST '127.0.0.1:80/dao/task_dao.es?method=load' -d '
# {"from":0,"size":10,"level":1}
# '

# curl -X GET '127.0.0.1:80/api/task.json?method=getmore'

# curl -X GET '127.0.0.1:80/api/script.json?method=get&type=douban-movie-detail'
curl -X GET '127.0.0.1:80/api/test.json?method=get&type=douban-movie-detail'