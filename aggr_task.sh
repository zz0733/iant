#!/bin/bash
curl -X POST 'http://127.0.0.1:9200/task/table/_search?pretty' -d '
{
    "aggs" : {
        "tcount" : {
            "terms" : { "field" : "type" }
        }
    }
}
'