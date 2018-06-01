#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/link_v4

#取别名
# curl -XPUT http://localhost:9200/link_v4/_alias/link


curl -XPOST 'localhost:9200/link_v4/_close'

curl -XPUT http://localhost:9200/link_v4/_settings?pretty -d '
{
  "index": {
    "analysis": {
      "analyzer": {
        "ik_smart_synonym": {
          "tokenizer": "ik_smart",
          "filter": [
            "synmone"
          ]
        }
      },
      "filter": {
        "synmone": {
          "type": "synonym",
          "synonyms_path": "analysis/synonym.txt"
        }
      }
    }
  }
}
'
curl -XPOST 'localhost:9200/link_v4/_open'
curl -XPUT http://localhost:9200/link_v4/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

#下载地址、分享地址，匹配对应的内容targets
curl -XPUT 'http://localhost:9200/link_v4/_mapping/table?pretty' -d '
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
    "lid": {
      "type": "keyword"
    },
    "title": {
      "type": "text",
      "analyzer": "ik_smart_synonym",
      "search_analyzer": "ik_smart_synonym"
    },
    "imdb": {
      "type": "keyword"
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
    "directors": {
      "type": "keyword",
      "index": false
    },
    "ctime": {
      "type": "long"
    },
    "utime": {
      "type": "long"
    },
    "season": {
      "type": "short"
    },
    "episode": {
      "type": "integer"
    },
    "target": {
      "type": "keyword"
    },
    "score": {
      "type": "float"
    },
    "level": {
      "type": "short"
    },
    "status": {
      "type": "short"
    },
    "webRTC": {
      "type": "short"
    },
    "feedimg": {
       "type": "keyword",
      "index": false
    }
  }
}
'