curl -H'Content-Type: application/json' -XPUT http://localhost:9200/_template/template_iant -d '
{
  "template": "*",
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "table": {
      "_all": {
        "enabled": false
      },
         "_source": {
            "enabled": false
        },
      "include_in_all": false,
      "properties": {
        "utime": {
          "type": "date",
          "format": "yyyy-MM-dd HH:mm:ss||yyyy-MM-dd||epoch_millis"
        },
        "ctime": {
          "type": "date",
          "format": "yyyy-MM-dd HH:mm:ss||yyyy-MM-dd||epoch_millis"
        }
      },
      "dynamic_templates": [
        {
          "string_fields": {
            "match": "*",
            "match_mapping_type": "string",
            "mapping": {
              "index": "not_analyzed",
              "type": "string"
            }
          }
        }
      ]
    }
  }
}
'