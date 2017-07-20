curl -XPOST '127.0.0.1:9200/_reindex' -d '
{
  "source": {
    "index": "content_v2"
  },
  "dest": {
    "index": "content_v3"
  },
  "script": {
    "inline": "if(ctx._source.article.epcount != null && ctx._source.article.epcount!=''){ ctx._source.article.epcount =Integer.parseInt(ctx._source.article.epcount); }",
    "lang": "painless"
  }
}
'