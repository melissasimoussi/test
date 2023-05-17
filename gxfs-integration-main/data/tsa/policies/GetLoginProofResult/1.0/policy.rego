package policies.GetLoginProofResult

claims := ocm.getLoginProofResult(input.requestId)

name = getName(claims)
given_name = getGivenName(claims)
family_name = getFamilyName(claims)
middle_name = getMiddleName(claims)
preferred_username = getPreferredUsername(claims)
gender = getGender(claims)
birthdate = getBirthdate(claims)
email = getEmail(claims)
sub = getSub(claims)
iss = getIss(claims)
roles = split(claims.Claims, "|") 
fedId = claims.FederationId
did = getIss(claims) 

email_verified {
	claims.email != ""
}

getName(c) = x {
	x = concat(" " , [c.FirstName, c.LastName]) 
}
getGivenName(c) = x {
	x = c.FirstName
}
getFamilyName(c) = x {
	x = c.LastName
}
getMiddleName(c) = x {
	x = c.MiddleName
}
getPreferredUsername(c) = x {
	x = c.PreferredUsername
}
getGender(c) = x {
	x = c.Gender
}
getBirthdate(c) = x {
	x = c.Birthdate
}
getEmail(c) = x {
	x = c.Email
}
getSub(c) = x {
	x = c.subjectDID
}
getIss(c) = x {
	x = c.issuerDID
}
