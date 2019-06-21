# oauth2-saml2bearerassertion
How to test the OAuth2 SAML Bearer Assertion grant using an REST-STS instance

Configuration with a single AM instance: http://openam.example.com:38080/openam

(This can happen with an external IDP instead (or IDP on different realm) but to have all-in-one AM, I used an STS instance)

Configurations
1. Change the security settings to use the JKS keystore and restart AM to take effect (because there is no SAML specific setting + STS can only read JKSkeystore see OPENAM-9385)

2. Configure the SAML providers (SP and IDP, both hosted) and use the same certificate alias as specified in the STS instance:

3. Configure an OAuth2 Provider with the default settings

4. Configure an OAuth2 Client (add a scope, for example, profile)

5. Create a REST-STS instance (OPENAM->SAML2):

Notes:

* The assertion must be signed
* STS can only read a JKS keystore. (Keystore password is the .storepass and the Signing/Private Key entry password is 'changeit' by default)
* "Service Provider entity ID" must be the OAuth2 Issuer (as it will need to match the AudienceRestriction block) → this is the hosted SP. (Note: this is the Audience parameter in SAML, OAuth2 provider is the Audience)
* Service Provider Assertion Consumer Service URL: you will grab this from the SP > Services > Assertion Consumer Service URL list e.g http://openam.example.com:38080/openam/Consumer/metaAlias/sp1 (Note: this is the Recipient parameter)
* SAML issuer ID: that's the IDP URL.
