package example.cacheGetByKey

default buy = false

currentPrice := cache.get(input.key, "", "").currentPrice
buy {
  currentPrice < 100
}



