# oauth2-saml2bearerassertion

How to test the OAuth2 SAML Bearer Assertion grant using an REST-STS instance

## Getting Started

Configuration with a single AM instance: http://openam.example.com:38080/openam

(This can happen with an external IDP instead (or IDP on different realm) but to have all-in-one AM, I used an STS instance)

### Configurations

1. Change the security settings to use the JKS keystore and restart AM to take effect (because there is no SAML specific setting + STS can only read JKSkeystore see OPENAM-9385)
![Screenshot](sts_keystore.png)
2.Configure the SAML providers (SP and IDP, both hosted) and use the same certificate alias as specified in the STS instance:
![Screenshot](saml_providers.png)
3.Configure an OAuth2 Provider with the default settings
4.Configure an OAuth2 Client (add a scope, for example, profile)
5.Create a REST-STS instance (OPENAM->SAML2):
![Screenshot](saml_sts_providers.png)
![Screenshot](saml_sts_configuration.png)

### Notes:

* The assertion must be signed
* STS can only read a JKS keystore. (Keystore password is the .storepass and the Signing/Private Key entry password is 'changeit' by default)
* "Service Provider entity ID" must be the OAuth2 Issuer (as it will need to match the AudienceRestriction block) → this is the hosted SP. (Note: this is the Audience parameter in SAML, OAuth2 provider is the Audience)
* Service Provider Assertion Consumer Service URL: you will grab this from the SP > Services > Assertion Consumer Service URL list e.g http://openam.example.com:38080/openam/Consumer/metaAlias/sp1 (Note: this is the Recipient parameter)
* SAML issuer ID: that's the IDP URL.


### Single commands:

1.Obtain an SSOToken:

```sh
curl -X POST \
  http://openam.example.com:38080/openam/json/authenticate \
  -H 'Accept-API-Version: resource=2.0, protocol=1.0' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -H 'X-OpenAM-Password: changeit' \
  -H 'X-OpenAM-Username: demo'
--RESPONSE:--
{
    "tokenId": "Os0teDqYckZFI8Q-o2rPSv86x6Q.*AAJTSQACMDEAAlNLABwvK2VuNktsZXgyeTVWSzQrZGRMeGpzN0JCbjg9AAR0eXBlAANDVFMAAlMxAAA.*",
    "successUrl": "/openam/console",
    "realm": "/"
}
```

2.Transform the SSOToken to a SAML assertion using the REST-STS instance:

```bash
curl -X POST \
  'http://openam.example.com:38080/openam/rest-sts/mytest?_action=translate' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/json' \
  -d '{ 
"input_token_state":{ 
  "token_type":"OPENAM",
  "session_id":"Os0teDqYckZFI8Q-o2rPSv86x6Q.*AAJTSQACMDEAAlNLABwvK2VuNktsZXgyeTVWSzQrZGRMeGpzN0JCbjg9AAR0eXBlAANDVFMAAlMxAAA.*"
 },
"output_token_state":{ 
  "token_type":"SAML2",
  "subject_confirmation":"BEARER"
 }
}'
--RESPONSE:--
{
    "issued_token": "<saml:Assertion xmlns:saml=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"s274ae80f03b097901a62dfe065db83821878e1b8e\" IssueInstant=\"2018-10-22T11:47:56Z\" Version=\"2.0\">\n<saml:Issuer>http://openam.example.com:38080/openam</saml:Issuer><ds:Signature xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">\n<ds:SignedInfo>\n<ds:CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>\n<ds:SignatureMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#rsa-sha1\"/>\n<ds:Reference URI=\"#s274ae80f03b097901a62dfe065db83821878e1b8e\">\n<ds:Transforms>\n<ds:Transform Algorithm=\"http://www.w3.org/2000/09/xmldsig#enveloped-signature\"/>\n<ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>\n</ds:Transforms>\n<ds:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"/>\n<ds:DigestValue>8A+8M3bSEzKj5CbLZ7HjZCByfQI=</ds:DigestValue>\n</ds:Reference>\n</ds:SignedInfo>\n<ds:SignatureValue>\nsH/6RWHHX3vX7yUeI5NEC1ZS8qs9w2vMmXJDwxSzAeZ41oQ6ejJdPj0xgGn3aa6TxyMDrcGWYHTq&#13;\n/sKDhAFImx8D1CSp+KZa8o/b5vX6VVOxUC6rMbsG8KZ9JJjIQhgnyyaGDvxUVk5g9TMMxOwPGqY2&#13;\nWfFnqt3/4ZNzNU+oUnH94d0wTLABFWSKTryiEzZkvGtIegNQRfETdEFyndahWZ6wpAAKoE72BJv8&#13;\nQOJXcbng+MGTmyjiPGCwlVL8iNTg4N16A0T3JxdKkHWmNqwZhTF0ZoeFIVdUd6y9BmXRwnkEePVn&#13;\n6F7xexi0/lmldH3GOwHGwofe7th4L1Hn4Orupg==\n</ds:SignatureValue>\n<ds:KeyInfo>\n<ds:X509Data>\n<ds:X509Certificate>\nMIIDYTCCAkmgAwIBAgIEDkXj/DANBgkqhkiG9w0BAQsFADBhMQswCQYDVQQGEwJVSzEQMA4GA1UE&#13;\nCBMHQnJpc3RvbDEQMA4GA1UEBxMHQnJpc3RvbDESMBAGA1UEChMJRm9yZ2VSb2NrMQswCQYDVQQL&#13;\nEwJBTTENMAsGA1UEAxMEdGVzdDAeFw0xODA0MDMxNDIxNDJaFw0yODAzMzExNDIxNDJaMGExCzAJ&#13;\nBgNVBAYTAlVLMRAwDgYDVQQIEwdCcmlzdG9sMRAwDgYDVQQHEwdCcmlzdG9sMRIwEAYDVQQKEwlG&#13;\nb3JnZVJvY2sxCzAJBgNVBAsTAkFNMQ0wCwYDVQQDEwR0ZXN0MIIBIjANBgkqhkiG9w0BAQEFAAOC&#13;\nAQ8AMIIBCgKCAQEAz6HdGc76+X9wRc+gyTMtZEPlbTRio4ugyTUBlEdDnE2MfAra3Wc12pcNRTT8&#13;\nm0Oj8nxHFWebYcQeqciYL4lmJg2ARLbMoQgXz9nyRp19cDLJZht9V193wsYWZFnBzVp73pPLWonS&#13;\nOJRWH+wZ7YJ9lR4KQKP7OVROUQCrFq9ensR+BRZa+QbnCQzK4RPss06kTGQ74HXkCAzZCslpS0H9&#13;\n7tPAnyLKPbuFP9l1Rv8I2FDPW5e3LIUw207VIL0Qoon/3OL5vxm6s9z5Xk+GSxztJonBxa/sGGjn&#13;\n9wn0WrVp3OkVs9zy4hIh/ktY5DAjhob+eG9XwmpT78ihTXwJW31dvwIDAQABoyEwHzAdBgNVHQ4E&#13;\nFgQUoi/ECAMD4NNxnxq6E5WgOsIYuhQwDQYJKoZIhvcNAQELBQADggEBAAtBs/QjN4pub0xOt8Tf&#13;\n2XHio/SrizkLDmfAJNsgExxi/w7jXS8LDxaAvIjzB+AChN0+A+geF4dxL6sW/It2F8w6rEeF3aou&#13;\n2nBjzloDZMHMgm11obQkSY9dxDmRhZKNJSOGqQACL5cgQY+m92kPzTG0dppJmgaGOJ8C2mhI33rR&#13;\nkIGlh5HFUO4N99PmghzX9u3PDNyCUPSKrmD9gS3PtF5KPvhaBuyO0GUQoj179Y5vGVxvmpoWXdIk&#13;\nbieMcK36DEBq3Dhm8DfRJGUCfLapdsxWw8MBIWF4o5p2q6wBPDH7enZQDfi2e3tI+hr+i+Swf5d3&#13;\nIYgeirlnHBcJyc7diis=\n</ds:X509Certificate>\n</ds:X509Data>\n</ds:KeyInfo>\n</ds:Signature><saml:Subject>\n<saml:NameID Format=\"urn:oasis:names:tc:SAML:1.0:nameid-format:unspecified\">demo</saml:NameID><saml:SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\">\n<saml:SubjectConfirmationData NotOnOrAfter=\"2018-10-22T11:57:56Z\" Recipient=\"http://openam.example.com:38080/openam/Consumer/metaAlias/sp1\"/></saml:SubjectConfirmation>\n</saml:Subject><saml:Conditions NotBefore=\"2018-10-22T11:47:56Z\" NotOnOrAfter=\"2018-10-22T11:57:56Z\">\n<saml:AudienceRestriction>\n<saml:Audience>http://openam.example.com:38080/openam/oauth2</saml:Audience>\n</saml:AudienceRestriction>\n</saml:Conditions>\n<saml:AuthnStatement AuthnInstant=\"2018-10-22T11:47:56Z\"><saml:AuthnContext><saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PreviousSession</saml:AuthnContextClassRef></saml:AuthnContext></saml:AuthnStatement></saml:Assertion>"
}
```

3.Exchange the Assertion(after escaping the special characters and using a base64url encoder) for an OAuth2 Access Token:

```bash
curl -X POST \
  http://openam.example.com:38080/openam/oauth2/access_token \
  -H 'Authorization: Basic bXlDbGllbnRJRDpwYXNzd29yZA==' \
  -H 'Cache-Control: no-cache' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Asaml2-bearer&assertion=PHNhbWw6QXNzZXJ0aW9uIHhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iIElEPSJzMjc0YWU4MGYwM2IwOTc5MDFhNjJkZmUwNjVkYjgzODIxODc4ZTFiOGUiIElzc3VlSW5zdGFudD0iMjAxOC0xMC0yMlQxMTo0Nzo1NloiIFZlcnNpb249IjIuMCI-CjxzYW1sOklzc3Vlcj5odHRwOi8vb3BlbmFtLmV4YW1wbGUuY29tOjM4MDgwL29wZW5hbTwvc2FtbDpJc3N1ZXI-PGRzOlNpZ25hdHVyZSB4bWxuczpkcz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnIyI-CjxkczpTaWduZWRJbmZvPgo8ZHM6Q2Fub25pY2FsaXphdGlvbk1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvMTAveG1sLWV4Yy1jMTRuIyIvPgo8ZHM6U2lnbmF0dXJlTWV0aG9kIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMC8wOS94bWxkc2lnI3JzYS1zaGExIi8-CjxkczpSZWZlcmVuY2UgVVJJPSIjczI3NGFlODBmMDNiMDk3OTAxYTYyZGZlMDY1ZGI4MzgyMTg3OGUxYjhlIj4KPGRzOlRyYW5zZm9ybXM-CjxkczpUcmFuc2Zvcm0gQWxnb3JpdGhtPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwLzA5L3htbGRzaWcjZW52ZWxvcGVkLXNpZ25hdHVyZSIvPgo8ZHM6VHJhbnNmb3JtIEFsZ29yaXRobT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS8xMC94bWwtZXhjLWMxNG4jIi8-CjwvZHM6VHJhbnNmb3Jtcz4KPGRzOkRpZ2VzdE1ldGhvZCBBbGdvcml0aG09Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvMDkveG1sZHNpZyNzaGExIi8-CjxkczpEaWdlc3RWYWx1ZT44QSs4TTNiU0V6S2o1Q2JMWjdIalpDQnlmUUk9PC9kczpEaWdlc3RWYWx1ZT4KPC9kczpSZWZlcmVuY2U-CjwvZHM6U2lnbmVkSW5mbz4KPGRzOlNpZ25hdHVyZVZhbHVlPgpzSC82UldISFgzdlg3eVVlSTVORUMxWlM4cXM5dzJ2TW1YSkR3eFN6QWVaNDFvUTZlakpkUGoweGdHbjNhYTZUeHlNRHJjR1dZSFRxCi9zS0RoQUZJbXg4RDFDU3ArS1phOG8vYjV2WDZWVk94VUM2ck1ic0c4S1o5SkpqSVFoZ255eWFHRHZ4VVZrNWc5VE1NeE93UEdxWTIKV2ZGbnF0My80Wk56TlUrb1VuSDk0ZDB3VExBQkZXU0tUcnlpRXpaa3ZHdEllZ05RUmZFVGRFRnluZGFoV1o2d3BBQUtvRTcyQkp2OApRT0pYY2JuZytNR1RteWppUEdDd2xWTDhpTlRnNE4xNkEwVDNKeGRLa0hXbU5xd1poVEYwWm9lRklWZFVkNnk5Qm1YUndua0VlUFZuCjZGN3hleGkwL2xtbGRIM0dPd0hHd29mZTd0aDRMMUhuNE9ydXBnPT0KPC9kczpTaWduYXR1cmVWYWx1ZT4KPGRzOktleUluZm8-CjxkczpYNTA5RGF0YT4KPGRzOlg1MDlDZXJ0aWZpY2F0ZT4KTUlJRFlUQ0NBa21nQXdJQkFnSUVEa1hqL0RBTkJna3Foa2lHOXcwQkFRc0ZBREJoTVFzd0NRWURWUVFHRXdKVlN6RVFNQTRHQTFVRQpDQk1IUW5KcGMzUnZiREVRTUE0R0ExVUVCeE1IUW5KcGMzUnZiREVTTUJBR0ExVUVDaE1KUm05eVoyVlNiMk5yTVFzd0NRWURWUVFMCkV3SkJUVEVOTUFzR0ExVUVBeE1FZEdWemREQWVGdzB4T0RBME1ETXhOREl4TkRKYUZ3MHlPREF6TXpFeE5ESXhOREphTUdFeEN6QUoKQmdOVkJBWVRBbFZMTVJBd0RnWURWUVFJRXdkQ2NtbHpkRzlzTVJBd0RnWURWUVFIRXdkQ2NtbHpkRzlzTVJJd0VBWURWUVFLRXdsRwpiM0puWlZKdlkyc3hDekFKQmdOVkJBc1RBa0ZOTVEwd0N3WURWUVFERXdSMFpYTjBNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DCkFROEFNSUlCQ2dLQ0FRRUF6NkhkR2M3NitYOXdSYytneVRNdFpFUGxiVFJpbzR1Z3lUVUJsRWREbkUyTWZBcmEzV2MxMnBjTlJUVDgKbTBPajhueEhGV2ViWWNRZXFjaVlMNGxtSmcyQVJMYk1vUWdYejlueVJwMTljRExKWmh0OVYxOTN3c1lXWkZuQnpWcDczcFBMV29uUwpPSlJXSCt3WjdZSjlsUjRLUUtQN09WUk9VUUNyRnE5ZW5zUitCUlphK1FibkNReks0UlBzczA2a1RHUTc0SFhrQ0F6WkNzbHBTMEg5Cjd0UEFueUxLUGJ1RlA5bDFSdjhJMkZEUFc1ZTNMSVV3MjA3VklMMFFvb24vM09MNXZ4bTZzOXo1WGsrR1N4enRKb25CeGEvc0dHam4KOXduMFdyVnAzT2tWczl6eTRoSWgva3RZNURBamhvYitlRzlYd21wVDc4aWhUWHdKVzMxZHZ3SURBUUFCb3lFd0h6QWRCZ05WSFE0RQpGZ1FVb2kvRUNBTUQ0Tk54bnhxNkU1V2dPc0lZdWhRd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFBdEJzL1FqTjRwdWIweE90OFRmCjJYSGlvL1NyaXprTERtZkFKTnNnRXh4aS93N2pYUzhMRHhhQXZJanpCK0FDaE4wK0ErZ2VGNGR4TDZzVy9JdDJGOHc2ckVlRjNhb3UKMm5Canpsb0RaTUhNZ20xMW9iUWtTWTlkeERtUmhaS05KU09HcVFBQ0w1Y2dRWSttOTJrUHpURzBkcHBKbWdhR09KOEMybWhJMzNyUgprSUdsaDVIRlVPNE45OVBtZ2h6WDl1M1BETnlDVVBTS3JtRDlnUzNQdEY1S1B2aGFCdXlPMEdVUW9qMTc5WTV2R1Z4dm1wb1dYZElrCmJpZU1jSzM2REVCcTNEaG04RGZSSkdVQ2ZMYXBkc3hXdzhNQklXRjRvNXAycTZ3QlBESDdlblpRRGZpMmUzdEkraHIraStTd2Y1ZDMKSVlnZWlybG5IQmNKeWM3ZGlpcz0KPC9kczpYNTA5Q2VydGlmaWNhdGU-CjwvZHM6WDUwOURhdGE-CjwvZHM6S2V5SW5mbz4KPC9kczpTaWduYXR1cmU-PHNhbWw6U3ViamVjdD4KPHNhbWw6TmFtZUlEIEZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6MS4wOm5hbWVpZC1mb3JtYXQ6dW5zcGVjaWZpZWQiPmRlbW88L3NhbWw6TmFtZUlEPjxzYW1sOlN1YmplY3RDb25maXJtYXRpb24gTWV0aG9kPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6Y206YmVhcmVyIj4KPHNhbWw6U3ViamVjdENvbmZpcm1hdGlvbkRhdGEgTm90T25PckFmdGVyPSIyMDE4LTEwLTIyVDExOjU3OjU2WiIgUmVjaXBpZW50PSJodHRwOi8vb3BlbmFtLmV4YW1wbGUuY29tOjM4MDgwL29wZW5hbS9Db25zdW1lci9tZXRhQWxpYXMvc3AxIi8-PC9zYW1sOlN1YmplY3RDb25maXJtYXRpb24-Cjwvc2FtbDpTdWJqZWN0PjxzYW1sOkNvbmRpdGlvbnMgTm90QmVmb3JlPSIyMDE4LTEwLTIyVDExOjQ3OjU2WiIgTm90T25PckFmdGVyPSIyMDE4LTEwLTIyVDExOjU3OjU2WiI-CjxzYW1sOkF1ZGllbmNlUmVzdHJpY3Rpb24-CjxzYW1sOkF1ZGllbmNlPmh0dHA6Ly9vcGVuYW0uZXhhbXBsZS5jb206MzgwODAvb3BlbmFtL29hdXRoMjwvc2FtbDpBdWRpZW5jZT4KPC9zYW1sOkF1ZGllbmNlUmVzdHJpY3Rpb24-Cjwvc2FtbDpDb25kaXRpb25zPgo8c2FtbDpBdXRoblN0YXRlbWVudCBBdXRobkluc3RhbnQ9IjIwMTgtMTAtMjJUMTE6NDc6NTZaIj48c2FtbDpBdXRobkNvbnRleHQ-PHNhbWw6QXV0aG5Db250ZXh0Q2xhc3NSZWY-dXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOmFjOmNsYXNzZXM6UHJldmlvdXNTZXNzaW9uPC9zYW1sOkF1dGhuQ29udGV4dENsYXNzUmVmPjwvc2FtbDpBdXRobkNvbnRleHQ-PC9zYW1sOkF1dGhuU3RhdGVtZW50Pjwvc2FtbDpBc3NlcnRpb24-&scope=profile&client_id=myClientID'
--RESPONSE:--
{
    "access_token": "nCQ3M6fq67aWRVpaQ24s9qSgBPs",
    "scope": "profile",
    "token_type": "Bearer",
    "expires_in": 3599
}
```
