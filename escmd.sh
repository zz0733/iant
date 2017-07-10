curl -X POST 'http://127.0.0.1:9200/script/table/douban-movie-link/_update?pretty' -d '
{
    "doc" : {
        "delete" : 1
    }
}
'
exit 0

curl -X POST 'http://127.0.0.1:9200/channel/_delete_by_query?pretty' -d '
{
  "query": {
      "match_all": {
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
      "must_not": {
        "exists": {
          "field": "ctime"
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

# curl -X GET 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
# {
#   "from": 0,
#   "size": 1,
#   "query": {
#       "match": {
#         "title":"巴霍巴利王2"
#       }
#   }
# }
# '
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
        "match": {"targets.id":"25580021"}
      }
    }
    
  },
  "from": 0,
  "size": 2
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
          "type":["utils-movie","douban-movie-detail","bdp-dynamic-list","douban-movie-link"]
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
  "size": 20,
  "_source": ["title","link","secret"],
  "query": {
    "bool": {
      "must": [
        {
          "range": {
            "ctime": {
              "gt": 1499681295
            }
          }
        }
      ]
    }
  }
}
'