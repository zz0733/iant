#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/user_v1



curl -XPUT http://localhost:9200/user_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
curl -XPUT 'http://localhost:9200/user_v1/_mapping/table?pretty' -d '
{
   "_source": {
        "enabled": true
  },
  "include_in_all": false,
  "properties": {
    "role": {
      "type": "integer"
    },
    "name": {
      "type": "keyword"
    },
    "pwd": {
      "type": "keyword"
    },
    "phone": {
      "type": "keyword"
    },
    "email": {
      "type": "keyword"
    },
    "avatar": {
      "type": "keyword"
    },
    "family": {
      "type": "keyword"
    },
    "ctime": {
      "type": "date"
    },
    "utime": {
      "type": "date"
    }
  }
}
'

#取别名
curl -XPUT http://localhost:9200/user_v1/_alias/user 
# curl -XGET http://localhost:9200/user_v1/_alias/*
# curl -XGET http://localhost:9200/*/_alias/user