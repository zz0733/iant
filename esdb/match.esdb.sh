#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/match_v1

#取别名
curl -XPUT http://localhost:9200/match_v1/_alias/match 


curl -XPUT http://localhost:9200/match_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0,
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
    "id": {
      "type": "keyword"
    },
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
    "link": {
      "type": "keyword"
    },
    "secret": {
      "type": "keyword"
    },
    "space": {
      "type": "long"
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