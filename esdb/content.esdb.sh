#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/content_v5

#取别名
curl -XPUT http://localhost:9200/content_v5/_alias/content 
# curl -XGET http://localhost:9200/content_v4/_alias/content
# curl -XGET http://localhost:9200/*/_alias/content


curl -XPOST 'localhost:9200/content_v5/_close'

curl -XPUT http://localhost:9200/content_v5/_settings?pretty -d '
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
curl -XPOST 'localhost:9200/content_v5/_open'
curl -XPUT http://localhost:9200/content_v5/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#电影、动漫、电视剧等内容资源
curl -XPUT 'http://localhost:9200/content_v5/_mapping/table?pretty' -d '
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
    "article": {
      "properties": {
        "template": {
          "type": "keyword"
        },
        "code": {
          "type": "keyword"
        },
        "title": {
          "type": "text",
          "analyzer": "ik_smart_synonym",
          "search_analyzer": "ik_smart_synonym"
        },
        "url": {
          "type": "keyword",
          "index": false
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
        "epcount": {
          "type": "integer"
        },
        "media": {
          "type": "keyword"
        }
      }
    },
    "evaluates": {
      "type": "nested",
      "properties": {
        "source": {
          "type": "keyword"
        },
        "star": {
          "type": "integer"
        },
        "rate": {
          "type": "integer"
        },
        "comment": {
          "type": "integer"
        },
        "like": {
          "type": "integer"
        },
        "order": {
          "type": "integer"
        }
      }
    },
    "action": {
      "properties": {
        "comment": {
          "type": "integer"
        },
        "like": {
          "type": "integer"
        },
        "exposure": {
          "type": "integer"
        },
        "click": {
          "type": "integer"
        },
        "visit": {
          "type": "integer"
        },
        "accept": {
          "type": "integer"
        }
      }
    },
    "author": {
      "properties": {
        "aname": {
          "type": "text"
        },
        "acover": {
          "type": "keyword",
          "index": false
        }
      }
    },
    "names": {
      "type": "text",
      "analyzer": "ik_smart_synonym",
      "search_analyzer": "ik_smart_synonym"
    },
    "genres": {
      "type": "text",
      "analyzer": "ik_smart_synonym",
      "search_analyzer": "ik_smart_synonym"
    },
    "actors": {
      "type": "text",
      "analyzer": "ik_smart_synonym",
      "search_analyzer": "ik_smart_synonym"
    },
    "directors": {
      "type": "text",
      "analyzer": "ik_smart_synonym",
      "search_analyzer": "ik_smart_synonym"
    },
    "images": {
      "type": "nested",
      "properties": {
        "id": {
          "type": "keyword"
        },
        "link": {
          "type": "keyword",
          "index": false
        }
      }
    },
    "tags": {
      "type": "nested",
      "properties": {
        "name": {
          "type": "keyword"
        },
        "kind": {
          "type": "keyword"
        },
        "score": {
          "type": "integer"
        }
      }
    },
    "digests": {
      "type": "nested",
      "properties": {
        "text": {
          "type": "text",
          "analyzer": "ik_smart_synonym",
          "search_analyzer": "ik_smart_synonym"
        },
        "content": {
          "type": "string",
          "index": "no"
        },
        "sort": {
          "type": "keyword"
        },
        "order": {
          "type": "integer"
        },
        "page": {
          "type": "integer"
        }
      }
    },
    "contents": {
      "type": "nested",
      "properties": {
        "text": {
          "type": "keyword",
          "index": false
        },
        "content": {
          "type": "keyword",
          "index": false
        },
        "sort": {
          "type": "keyword"
        },
        "order": {
          "type": "integer"
        },
        "page": {
          "type": "integer"
        }
      }
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
    "publish": {
      "properties": {
        "user": {
          "type": "keyword"
        },
        "role": {
          "type": "short"
        },
        "time": {
          "type": "date"
        },
        "status": {
          "type": "short"
        },
        "reason": {
          "type": "keyword",
          "index": false
        }
      }
    },
    "extends": {
      "type": "keyword",
      "index": false
    },
    "lpipe": {
      "properties": {
        "lid": {
          "type": "keyword"
        }, 
        "index": {
          "type": "integer"
        }, 
        "epmax": {
          "type": "integer"
        },
        "time": {
          "type": "date"
        }
      }
    },
    "lcount": {
      "type": "integer"
    },
    "imagick": {
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

curl -XPOST 'localhost:9200/content_v5/_open'