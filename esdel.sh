curl -X POST 'http://127.0.0.1:9200/link/_delete_by_query?pretty' -d '
{
  "size": 10,
  "sort": {
    "ctime": {
      "order": "desc"
    }
  },
  "query": {
    "bool": {
      "must_not": {
        "exists": {
          "field": "target"
        }
      },
       "must": {
        "range": {
          "ctime": {"lt":1525132800}
        }
      }
    }
  }
}
'