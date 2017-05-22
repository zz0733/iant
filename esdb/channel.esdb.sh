#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/channel_v1

#取别名
curl -XPUT http://localhost:9200/channel_v1/_alias/channel 
# curl -XGET http://localhost:9200/content_v1/_alias/*
# curl -XGET http://localhost:9200/*/_alias/content


curl -XPOST 'localhost:9200/channel/_close'

curl -XPUT http://localhost:9200/channel/_settings?pretty -d '
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
curl -XPOST 'localhost:9200/channel/_open'
curl -XPUT http://localhost:9200/channel/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#电影、动漫、电视剧等内容资源
curl -XPUT 'http://localhost:9200/channel/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "properties": {
    "media": {
      "type": "keyword"
    },
    "source": {
      "type": "keyword"
    },
    "groupby": {
      "type": "keyword"
    },
    "timeby": {
      "type": "keyword"
    },
    "channel": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
    },
    "url": {
      "type": "string",
      "index": "no"
    },
    "total": {
      "type": "integer"
    },
    "elements": {
      "properties": {
        "id": {
          "type": "keyword"
        },
        "code": {
          "type": "keyword"
        },
        "title": {
          "type": "text",
          "analyzer": "ik_max_word_synonym",
          "search_analyzer": "ik_max_word_synonym"
        },
        "page": {
          "type": "integer"
        }
      }
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