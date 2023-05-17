package policies.returnDID

concat_f(s,s2) = concat("", [s, s2])

_ = {
     "@context" : ["https://www.w3.org/ns/did/v1", "https://w3id.org/security/suites/jws-2020/v1"],
     "id" :  external.http.header("X-Did-Location"),
     "verificationMethod" : verification_methods(external.http.header("X-Did-Location"), external.http.header("X-Did-Transit-Engine")),
     "service":[{
          "id": concat_f(external.http.header("X-Did-Location"),"#catalog-desc"),
          "type": "gx-catalog-description", 
          "serviceEndpoint":concat_f("https://integration.gxfs.dev/api/self-descriptions/description?did=",urlquery.encode(external.http.header("X-Did-Location")))
     },{
           "id": concat_f(external.http.header("X-Did-Location"),"#trusted-connection"),
           "type": "gx-trusted-connection", 
           "serviceEndpoint": "https://integration.gxfs.dev/ocm-provider-connection/v1/invitation-url?alias=trust"
     }]
}