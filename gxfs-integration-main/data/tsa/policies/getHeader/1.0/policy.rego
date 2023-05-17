package example.getHeader

# gets the value for "x-cache-key" header and return it in the result
# result is empty if the "x-cache-key" header is not sent in the request
key := external.http.header("X-Cache-Key")
