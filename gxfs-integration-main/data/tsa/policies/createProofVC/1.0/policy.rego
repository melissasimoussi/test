package policies.createProofVC

_ := add_vc_proof(external.http.header("X-Did-Transit-Engine"), external.http.header("X-Did-Key"), input)