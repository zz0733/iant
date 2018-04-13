#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/match_v1

#取别名
curl -XPUT http://localhost:9200/match_v1/_alias/match 


curl -XPUT http://localhost:9200/match_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

#下载地址、分享地址，匹配对应的内容targets
curl -XPUT 'http://localhost:9200/match_v1/_mapping/table?pretty' -d '
{
  "_all": {
    "enabled": false
  },
  "include_in_all": false,
  "dynamic_templates": [
    {
      "string_fields": {
        "match": "*",
        "match_mapping_type": "string",
        "mapping": {
          "index": "not_analyzed",
          "type": "string"
        }
      }
    }
  ],
  "properties": {
    "season": {
      "type": "short"
    },
    "episode": {
      "type": "integer"
    },
    "title": {
      "type": "keyword",
      "index": false
    },
    "docid": {
      "type": "keyword"
    },
    "score": {
      "type": "integer"
    },
    "ctime": {
      "type": "date"
    },
    "status": {
      "type": "short"
    }
  }
}
'