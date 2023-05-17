package policies.createProofVP

_ := add_vp_proof(external.http.header("X-Did-Location"), external.http.header("X-Did-Transit-Engine"), external.http.header("X-Did-Key"), input)
