#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/script_v1

#取别名
curl -XPUT http://localhost:9200/script_v1/_alias/script 


curl -XPUT http://localhost:9200/script/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

curl -XPUT 'http://localhost:9200/script/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "type": {
      "type": "keyword"
    },
    "script": {
      "type": "string",
      "index": "no"
    },
    "delete": {
      "type": "short"
    },
    "create_time": {
      "type": "date"
    },
    "update_time": {
      "type": "date"
    }
  }
}
'