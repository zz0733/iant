#!/bin/bash
#创建索引
curl -XPUT http://localhost:9200/content_v1

#取别名
curl -XPUT http://localhost:9200/content_v1/_alias/content 
# curl -XGET http://localhost:9200/content_v1/_alias/*
# curl -XGET http://localhost:9200/*/_alias/content


curl -XPOST 'localhost:9200/content/_close'

curl -XPUT http://localhost:9200/content/_settings?pretty -d '
{
  "index": {
    "analysis": {
      "analyzer": {
        "ik_smart_synonym": {
          "tokenizer": "ik_smart",
          "filter": [
            "synonym"
          ]
        },
        "ik_smart_standard": {
          "tokenizer": "ik_smart",
          "filter": [
            "synonym",
            "standard"
          ]
        },
        "ik_max_word_synonym": {
          "tokenizer": "ik_max_word",
          "filter": [
            "synonym"
          ]
        }
      },
      "filter": {
        "synonym": {
          "type": "synonym",
          "synonyms_path": "analysis/synonym.txt"
        },
        "standard": {
          "type": "standard",
          "synonyms_path": "analysis/standard.txt"
        }
      }
    }
  }
}
'
curl -XPOST 'localhost:9200/content/_open'
curl -XPUT http://localhost:9200/content/_settings?pretty -d '
{
  "index": {
    "number_of_replicas": 0
  }
}
'
#电影、动漫、电视剧等内容资源
curl -XPUT 'http://localhost:9200/content/_mapping/table?pretty' -d '
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
          "analyzer": "ik_max_word_synonym",
          "search_analyzer": "ik_max_word_synonym"
        },
        "url": {
          "type": "string",
          "index": "no"
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
          "type": "string",
          "index": "no"
        }
      }
    },
    "names": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
    },
    "genres": {
      "type": "text",
      "analyzer": "ik_max_word_synonym",
      "search_analyzer": "ik_max_word_synonym"
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
    "images": {
      "type": "nested",
      "properties": {
        "id": {
          "type": "keyword"
        },
        "link": {
          "type": "string",
          "index": "no"
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
          "analyzer": "ik_max_word_synonym",
          "search_analyzer": "ik_max_word_synonym"
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
          "type": "text",
          "analyzer": "ik_max_word_synonym",
          "search_analyzer": "ik_max_word_synonym"
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
    "issueds": {
      "type": "nested",
      "properties": {
        "region": {
          "type": "text",
          "analyzer": "ik_smart_standard",
          "search_analyzer": "ik_smart_standard"
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
          "type": "string",
          "index": "no"
        }
      }
    },
    "extends": {
      "type": "string",
      "index": "no"
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