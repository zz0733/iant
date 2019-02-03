#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/topic_v1


curl -XPUT http://localhost:9200/topic_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

curl -XPOST 'localhost:9200/topic_v1/_close'

curl -XPUT http://localhost:9200/topic_v1/_settings?pretty -d '
{
  "index": {
    "analysis": {
      "analyzer": {
        "ik_smart_synonym": {
          "tokenizer": "ik_smart",
          "filter": [
            "synmone"
          ]
        },
        "ik_smart_synmgroup": {
          "tokenizer": "ik_smart",
          "filter": [
            "synmone",
            "synmgroup"
          ]
        },
        "ik_max_word_synonym": {
          "tokenizer": "ik_max_word",
          "filter": [
            "synmone"
          ]
        }
      },
      "filter": {
        "synmone": {
          "type": "synonym",
          "synonyms_path": "analysis/synonym.txt"
        },
        "synmgroup": {
          "type": "synonym",
          "synonyms_path": "analysis/standard.txt"
        }
      }
    }
  }
}
'

curl -XPOST 'localhost:9200/topic_v1/_open'


# sortId:{1:"资讯", 2:"在线视频", 3:"离线视频", 4:"图集"}
curl -XPUT 'http://localhost:9200/topic_v1/_mapping/table?pretty' -d '
{
   "_all": {
        "enabled": false
   },
   "_source": {
      "enabled": false
  },
  "include_in_all": false,
  "properties": {
     "title": {
        "type": "text"
     }
  }
}
'

#取别名
curl -XPUT http://localhost:9200/topic_v1/_alias/topic
# curl -XGET http://localhost:9200/topic_v1/_alias/*
# curl -XGET http://localhost:9200/*/_alias/topic