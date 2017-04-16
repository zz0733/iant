 curl -XPOST 'http://127.0.0.1:9200/script/table/_search?pretty' -d '
    {
      "query": { "match_all": {} },
      "from": 0,
      "size": 10
    }
 '

 exit 0

 curl -XPOST 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
{
  "query": {
    "bool": {
      "filter": {
        "term": {
          "level": 0
        }
      }
    }
  },
  "from": 0,
  "size": 10
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
      "create_time": {
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