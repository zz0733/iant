#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/collect_v1

#取别名
curl -XPUT http://localhost:9200/collect_v1/_alias/collect 


curl -XPUT http://localhost:9200/collect/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#收集抓取等渠道的数据
curl -XPUT 'http://localhost:9200/collect/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "type": {
      "type": "keyword"
    },
    "task": {
      "type": "string",
      "index": "no"
    },
    "data": {
      "type": "string",
      "index": "no"
    },
    "handlers": {
      "type": "keyword"
    },
    "ctime": {
      "type": "date"
    }
  }
}
'