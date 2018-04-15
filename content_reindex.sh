curl -XPOST 'http://127.0.0.1:9200/_reindex' -d '
{
  "source" : {
  	"index" : "content_v4"
  },
  "dest": {
      "index": "content_v5"
  },
  "script" : {
  	"lang":"painless",
  	"inline":"ctx._source.remove(\"evaluates\"); ctx._source.remove(\"digests\"); ctx._source.remove(\"contents\"); ctx._source.remove(\"actors\"); ctx._source.remove(\"extends\");"
  }
}
'