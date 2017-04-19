#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/image_v1

#取别名
curl -XPUT http://localhost:9200/image_v1/_alias/image 


curl -XPUT http://localhost:9200/image/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

curl -XPUT 'http://localhost:9200/image/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "path": {
      "type": "string",
      "index": "no"
    },
    "link": {
      "type": "keyword"
    },
    "originid": {
      "type": "keyword"
    },
    "width": {
      "type": "integer"
    },
    "height": {
      "type": "integer"
    },
    "format": {
      "type": "keyword"
    },
    "create_time": {
      "type": "date"
    }
  }
}
'