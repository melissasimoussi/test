package policies.examplePolicy

import future.keywords.in

default trusted = false

trusted{
    issuer := input.issuer
    issuer in data.trustlist
}