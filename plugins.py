from elasticsearch import Elasticsearch

# create an instance of the Elasticsearch client
es = Elasticsearch([{'host': 'localhost', 'port': 9200}])

# define the search query
query = {
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "dock_image": {
                            "query": "pl-dylld",
                            "fuzziness": "auto"
                        }
                    }
                },
                {
                    "match": {
                        "min_cpu_limit": {
                            "query": 1000,
                            "fuzziness": "auto"
                        }
                    }
                }
            ]
        }
    }
}

# execute the search query
result = es.search(index='_all', body=query)

# print the search results
print(result)
