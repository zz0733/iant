
curl -X GET 'http://127.0.0.1:9200/content/table/_search?pretty' -d '
{
  "from": 0,
  "size": 1,
  "query": {
    "multi_match": {
      "query": "Breakup",
      "type": "best_fields",
      "fields": [
        "article.title",
        "names"
      ],
      "operator": "and",
      "minimum_should_match": "60%"
    }
  }
}
'
exit 0
curl -X GET 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  "from": 0,
  "size": 1,
  "sort":{
    "ctime":{
      "order":"asc"
    }
  },
  "query": {
    "bool": {
    "filter":{
      "range":{
        "ctime" :{
          "gt":0,
          "lte":1493715786318
        }
      }
    },
      "must_not": {
        "term": {
          "status":-1
        }
      },
      "must_not": {
        "term": {
          "status":1
        }
      }
    }
  }
}
'
exit 0

 curl -XPOST 'http://127.0.0.1:9200/link/table/_search?pretty' -d '
{
  
  "query": {
    "match": {"title":"鲜肉"}
  },
  "from": 0,
  "size": 5
}
 '
exit 0
curl -XPOST 'http://127.0.0.1:9200/content/table/_search?pretty' -d '
{
  
  "query": {
    "nested":{
      "path" : "issueds",
      "query":{
        "match": {"issueds.country":"北京"}
      }
    }
    
  },
  "from": 0,
  "size": 2
}
 '
 exit 0

 curl -XGET 'http://127.0.0.1:9200/collect/table/_search?pretty' -d '
 {
  "query": {
    "bool": {
      "filter": {
        "terms": {
          "handlers": [
            "content",
            "logger"
          ]
        }
      }
    }
  },
  "from": 0,
  "size": 10
}
 '
 exit 0

#  curl -XPOST 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
# {
#   "query": {
#     "bool": {
#       "filter": {
#         "term": {
#           "level": 0
#         }
#       }
#     }
#   },
#   "from": 0,
#   "size": 10
# }
#  '
# exit 0
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