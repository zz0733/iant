 curl -XPOST 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
    {
      "query": { "match_all": {} },
      "from": 0,
      "size": 10
    }'