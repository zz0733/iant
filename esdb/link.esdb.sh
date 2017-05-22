#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/link_v1

#取别名
curl -XPUT http://localhost:9200/link_v1/_alias/link 


curl -XPOST 'localhost:9200/link/_close'

curl -XPUT http://localhost:9200/link/_settings?pretty -d '
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
curl -XPOST 'localhost:9200/link/_open'
curl -XPUT http://localhost:9200/link/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'

#下载地址、分享地址，匹配对应的内容targets
curl -XPUT 'http://localhost:9200/link/_mapping/table?pretty' -d '
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
    "season": {
      "type": "short"
    },"episode": {
      "type": "integer"
    },
    "title": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
    },
    "paths": {
      "type": "nested",
      "properties": {
        "name": {
          "type": "text",
          "analyzer": "ik_max_word_synonym",
          "search_analyzer": "ik_max_word_synonym"
        },
        "length": {
          "type": "long"
        }
      }
    },
    "extends": {
      "type": "string",
      "index": "no"
    },
    "targets": {
      "type": "nested",
      "properties": {
        "id": {
          "type": "keyword"
        },
        "score": {
          "type": "integer"
        },
        "status": {
          "type": "integer"
        }
      }
    },
    "md5": {
      "type": "keyword"
    },
    "code": {
      "type": "keyword"
    },
    "link": {
      "type": "keyword"
    },
    "format": {
      "type": "keyword"
    },
    "source": {
      "type": "keyword"
    },
    "space": {
      "type": "long"
    },
    "actors": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
    },
    "directors": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
    },
    "issueds": {
      "type": "nested",
      "properties": {
        "region": {
          "type": "text",
          "analyzer": "ik_smart_synmgroup",
          "search_analyzer": "ik_smart_synmgroup"
        },
        "country": {
          "type": "text",
          "analyzer": "ik_smart_synonym",
          "search_analyzer": "ik_smart_synonym"
        },
        "time": {
          "type": "date"
        },
        "order": {
          "type": "integer"
        }
      }
    },
    "ctime": {
      "type": "date"
    },
    "utime": {
      "type": "date"
    },
    "status": {
      "type": "short"
    }
  }
}
'