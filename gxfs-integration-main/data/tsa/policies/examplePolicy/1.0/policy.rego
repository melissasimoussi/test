package policies.examplePolicy

default allow = false

allow{
    input.message == "example"
}
