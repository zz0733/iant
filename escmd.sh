curl -X POST 'http://127.0.0.1:9200/script/table/douban-movie-link/_update?pretty' -d '
{
    "doc" : {
        "delete" : 1
    }
}
'
exit 0

curl -X POST 'http://127.0.0.1:9200/content/_delete_by_query?pretty' -d '
{
  "query": {
      "match": {
        "_id":"80040824"
      }
  }
}
'
curl -X POST 'http://127.0.0.1:9200/content/table/_update_by_query?pretty' -d '
{
  "script": {
    "inline": "ctx._source.ctime = ctx._source.utime;",
    "lang": "painless"
  },
  "query": {
    "bool": {
      "must_not": {
        "exists": {
          "field": "ctime"
        }
      }
    }
  }
}
'
curl -X POST 'http://127.0.0.1:9200/content/table/_search?pretty' -d '
{
  "query": {
      "bool": {
        "filter":{"range":{"lcount":{"gt":0}}}
       }
    }
}
'

curl -X POST 'http://127.0.0.1:9200/content/table/_search' -d '
{
  "size":10,
  "query": {
    "bool": {
      "must": {
        "exists": {
          "field": "scecret"
        }
      }
    }
  }
}
'

# curl -X GET 'http://127.0.0.1:9200/script/table/_search?pretty' -d '
# {
#   "from": 0,
#   "size": 100,
#   "_source":false,
#   "query": {
#     "bool": {
#       "must_not": {
#         "term": {
#           "delete": "1"
#         }
#       }
#     }
#   }
# }
# '
# exit 0

curl -X GET 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  "from": 0,
  "size": 1,
  "query": {
      "match": {
        "_id":"m0483652730"
      }
  }
}
'
# exit 0
curl -X POST 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  "query": {
    "match": {
      "status": 1
    }
  }
}
'
exit 0
curl -X POST 'http://127.0.0.1:9200/link/table/_update_by_query' -d '
{
  "script": {
    "inline": "ctx._source.status=0; ctx._source.targets=null;",
    "lang": "painless"
  },
  "query": {
    "match": {
      "status": 1
    }
  }
}
'
exit 0
curl -X GET 'http://127.0.0.1:9200/content/table/_search?pretty' -d '
{
  "from": 0,
  "size": 2,
  "query": {
    "match": {
      "names": "继"
    }
  },
  "highlight": {
    "order": "score",
    "fields": {
      "names": {
        "fragment_size": 50,
        "number_of_fragments": 3,
        "fragmenter": "span"
      }
    }
  }
}
'
exit 0
# curl -X GET 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
# {
#   "from": 0,
#   "size": 1,
#   "sort":{
#     "ctime":{
#       "order":"asc"
#     }
#   },
#   "query": {
#     "bool": {
#     "filter":{
#       "range":{
#         "ctime" :{
#           "gt":0,
#           "lte":1493715786318
#         }
#       }
#     },
#       "must_not": {
#         "term": {
#           "status":-1
#         }
#       },
#       "must_not": {
#         "term": {
#           "status":1
#         }
#       }
#     }
#   }
# }
# '
# exit 0

 curl -XPOST 'http://127.0.0.1:9200/content/table/_search?pretty' -d '
{
  
  "query": {
    "match": {"article.year":"2017"}
  },
  
  "from": 0,
  "size": 3
}
 '
exit 0
curl -XPOST 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  
  "query": {
    "nested":{
      "path" : "targets",
      "query":{
        "match": {"targets.id":"57991420"}
      }
    }
    
  },
  "from": 0,
  "size": 2
}
 '

 curl -XPOST 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  "query": {
    "bool": {
      "must": [
        {
          "nested": {
            "path": "issueds",
            "query": {
              "match": {
                "issueds.region": "4026763474"
              }
            }
          }
        },
        {
          "match": {
            "title": "魔弦传说"
          }
        }
      ]
    }
  },
  "from": 0,
  "size": 20
}
 '
#  exit 0

#  curl -XGET 'http://127.0.0.1:9200/collect/table/_search?pretty' -d '
#  {
#   "query": {
#     "bool": {
#       "filter": {
#         "terms": {
#           "handlers": [
#             "content",
#             "logger"
#           ]
#         }
#       }
#     }
#   },
#   "from": 0,
#   "size": 10
# }
#  '
#  exit 0

 curl -XPOST 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
{
  "query": {
    "bool": {
      "filter": {
        "term": {
          "level": 0
        }
      },
      "must":{
        "terms":{
          "type":["ed2000-movie-torrent"]
        }
      }
    }
  },
  "from": 0,
  "size": 10
}
 '
exit 0
# curl -XGET 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
# {
#   "query": { 
#     "bool": { 
#       "filter": [ 
#         { "range": { "create_time": { "gt": "2017-04-20" }}} 
#       ]
#     }
#   }
# }'
# exit 0

curl -XPOST 'http://127.0.0.1:9200/script/table/_search?pretty' -d '
{
  "query": { 
    "bool": { 
      "must": [
        { "match": { "_id":   "douban-movie-detail"        }}
      ]
      ,
      "filter": [ 
        { "term":  { "delete": 0 }}
      ]
    }
  }
}
 '

# exit 0

# curl -X GET 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
# {
#     "query" : {
#         "constant_score" : {
#             "filter" : {
#                 "terms" : { 
#                     "_id" : ["AVtvoQQp0ALdV9cbJBtA", "AVtvtDi10ALdV9cbJBtF"]
#                 }
#             }
#         }
#     }
# }
# '

# curl -X POST 'http://127.0.0.1:9200/task/table/_delete_by_query?pretty' -d '
# {
#   "query": { 
#     "match_all" : {}
#   }
# }
# '

exit 0
curl -X GET 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
{
  "from": 0,
  "size": 1,
  "sort": [
    {
      "ctime": {
        "order": "asc"
      }
    }
  ],
  "query": {
    "bool": {
      "filter": {
        "terms": {
          "status": 0,
          "level": 0
        }
      }
    }
  }
}
'

curl -XGET 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  "from": 0,
  "size": 100,
  "_source":["title"],
  "query": {
    "bool": {
      "must": [
        {
          "range": {
            "ctime": {
              "gt": 1499957657
            }
          }
        }
      ]
    }
  }
}
'

curl -XGET 'http://localhost:9200/link/_analyze?pretty' -d '
{
  "field" : "title",
  "text" : "海贼王800"
}
'
curl -XGET 'http://localhost:9200/link/_search?pretty' -d '
{
  "size": 0,
  "aggs": {
       "term": {
           "field": "title"
       }
  }
}
'

curl -XGET "http://localhost:9200/meta/_search?pretty" -d'
{  
    "size" : 20,  
    "sort" : {"epindex":"desc"},  
    "query": {
       "match":{
        "title" : "十三省"
       }
    }
}'


curl -XGET "http://localhost:9200/link/_search?pretty" -d'
{  
    "size" : 20,  
    "sort" : {"ctime":"desc"},  
    "query": {
       "match":{
        "format" : "vmeta"
       }
    }
}'


curl -XGET "http://localhost:9200/link/_search?pretty" -d'
{
  "size": 20,
  "sort": {
    "episode": "desc"
  },
  "query": {
    "bool": {
      "must": [
        {
          "match": {
            "format": "vmeta"
          }
        },
        {
          "match": {
            "title": "虎啸龙吟"
          }
        }
      ]
    }
  }
}
'

curl -XGET "http://localhost:9200/link/_search?pretty" -d'
{
  "size": 20,
  "sort": {
    "ctime": "desc"
  },
  "query": {
    "match": {
       "_id":"v1051433666"
    }
  }
}
'

curl -XPOST "http://localhost:9200/link/_delete_by_query?pretty" -d'
{
  "size": 20,
  "sort": {
    "ctime": "desc"
  },
  "query": {
    "match": {
       "_id":"v0585527237"
    }
  }
}
'

curl -XGET "http://localhost:9200/link/_search?pretty" -d'
{
    "size":10000,
    "query": {
        "bool" : {
           "must" : {
             "match" : { "format":"vmeta"}
           }
        }
    }
}
'

curl -XGET "http://localhost:9200/link/_search?pretty" -d'
{
  "size": 20,
  "sort": {
    "ctime": "desc"
  },
  "query": {
    "match": {
      "title" :{
        "query":"海贼王800",
        "minimum_should_match":"80%"
      }
    }
  }
}
'