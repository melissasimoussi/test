package example.publicKeysForDIDs

publicKeys := getKeys(input)

getKeys(i) = res {
	doc1 = did.resolve(data.dids[0])
	doc2 = did.resolve(data.dids[1])
	res := array.concat([doc1.didDocument.verificationMethod[0].publicKeyMultibase], [doc2.didDocument.verificationMethod[0].publicKeyMultibase])
}
