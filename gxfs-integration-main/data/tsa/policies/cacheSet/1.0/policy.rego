package example.cacheSet

default success = false

success = true {
    msg := cache.set(data.key, "mynamespace", data.scope, input)
    msg == "success"
}