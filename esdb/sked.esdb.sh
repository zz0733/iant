#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/sked_v1



curl -XPUT http://localhost:9200/sked_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#电影、动漫、电视剧等内容资源
curl -XPUT 'http://localhost:9200/sked_v1/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "cmd": {
      "type": "integer"
    },
    "start": {
      "type": "date"
    },
    "params": {
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
curl -XPUT http://localhost:9200/sked_v1/_alias/sked