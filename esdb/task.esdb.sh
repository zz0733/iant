#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/task_v1

#取别名
curl -XPUT http://localhost:9200/task_v1/_alias/task 


curl -XPUT http://localhost:9200/task/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  },
  "settings": {
    "index.mapper.dynamic": false
  }
}
'

curl -XPUT 'http://localhost:9200/task/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "parent_id": {
      "type": "keyword"
    },
    "batch_id": {
      "type": "keyword"
    },
    "job_id": {
      "type": "keyword"
    },
    "type": {
      "type": "keyword"
    },
    "url": {
      "type": "keyword"
    },
    "params": {
      "type": "string",
      "index": "no"
    },
    "level": {
      "type": "integer"
    },
    "status": {
      "type": "short"
    },
    "source": {
      "type": "string",
      "index": "no"
    },
    "creator": {
      "type": "string",
      "index": "no"
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