package example.CredentialIssueRequest

_ = {
        "connectionId": "conn-id",
        "credentialDefinitionId": "cred-def-id",
        "comment": "Created",
        "preview": {
            "@type": "https://didcomm.org/issue-credential/1.0/credential-preview",
            "attributes": [
                {
                    "name": "email",
                    "value": "test_fname_3"
                },
                {
                    "name": "name",
                    "value": "test_lname_3"
                },
                {
                    "name": "number",
                    "value": "test_gender_3"
                }
            ]
        },
        "autoAcceptCredential": "never"
    }