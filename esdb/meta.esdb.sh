#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/meta_v1

#取别名
curl -XPUT http://localhost:9200/meta_v1/_alias/meta 
# curl -XGET http://localhost:9200/content_v1/_alias/*
# curl -XGET http://localhost:9200/*/_alias/content


curl -XPOST 'localhost:9200/meta_v1/_close'

curl -XPUT http://localhost:9200/meta_v1/_settings?pretty -d '
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
curl -XPOST 'localhost:9200/meta_v1/_open'
curl -XPUT http://localhost:9200/meta_v1/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#电影、动漫、电视剧等内容资源,一集条记录
curl -XPUT 'http://localhost:9200/meta_v1/_mapping/table?pretty' -d '
{
  "include_in_all": false,
  "dynamic_templates": [
    {
      "cn": {
        "match": "*_cn",
        "match_mapping_type": "text",
        "mapping": {
          "type": "text",
          "analyzer": "ik_max_word",
          "search_analyzer": "ik_max_word"
        }
      }
    }
  ],
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
    "url": {
      "type": "string",
      "index": "no"
    },
    "media": {
      "type": "keyword"
    },
    "source": {
      "type": "keyword"
    },
    "cost": {
      "type": "integer"
    },
    "year": {
      "type": "integer"
    },
    "lang": {
      "type": "keyword"
    },
    "imdb": {
      "type": "keyword"
    }, 
    "season": {
      "type": "integer"
    },
    "epcount": {
      "type": "integer"
    },
    "epindex": {
      "type": "integer"
    },  
    "playcount": {
      "type": "integer"
    },    
    "voteup": {
      "type": "integer"
    },  
    "score": {
      "type": "integer"
    },
    "status": {
      "type": "integer"
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

curl -XPOST 'localhost:9200/meta_v1/_open'