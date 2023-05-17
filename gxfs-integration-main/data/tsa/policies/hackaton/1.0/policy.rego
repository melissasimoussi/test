package example.hackaton

import future.keywords.in

default trusted = false
default expired = false
default valid = false

trusted {
    m := input.issuer
    m in data.trustlist
}

expired {
    exp:= time.parse_ns("2006-01-02T15:04:05Z07:00",input.expirationDate)
    now:=time.now_ns()
    now>exp
}

valid = semanticallyValid(input)

semanticallyValid(i) = res {
    now:=time.now_ns()
    vac:= data.vaccines[i.credentialSubject.vaccine.vacCode].active == true
    vacDate:=time.parse_ns("2006-01-02T15:04:05Z07:00",i.credentialSubject.dateOfVaccination)
    vacStillValid:=now < (vacDate+15552000000000000)
    res := vac == vacStillValid
}
