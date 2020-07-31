let fpMediaCreateBody = """
{
  "settings": {
    "max_result_window": 100000,
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "aperture": {
        "type": "float"
      },
      "dateTime": {
        "type": "date",
        "format": "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
      },
      "durationSeconds" : {
        "type" : "float"
      },
      "exposureTime" : {
        "type" : "float"
      },
      "fNumber" : {
        "type" : "float"
      },
      "focalLengthMm" : {
        "type" : "float"
      },
      "iso" : {
        "type" : "integer"
      },
      "lengthInBytes" : {
        "type" : "long"
      },
      "location": {
        "type": "geo_point"
      }
    }
  }
}
"""


let fpAliasCreateBody = """
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "dateAdded": {
        "type": "date"
      },
      "dateLastIndexed": {
        "type": "date"
      }
    }
  }
}
"""
