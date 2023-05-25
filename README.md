# About

[![Build status](https://github.com/rgl/terraform-keycloak/workflows/build/badge.svg)](https://github.com/rgl/terraform-keycloak/actions?query=workflow%3Abuild)

This initializes a Keycloak instance using the [mrparkers/terraform-provider-keycloak](https://github.com/mrparkers/terraform-provider-keycloak) Terraform provider.

This will:

* Create a test Keycloak instance inside a docker container using docker compose.
* Create the `example` realm.
  * Create the `alice` user.
  * Create the `administrators` group.
    * Assign the `example-go-saml` client `administrator` role.
    * Add the `alice` user as a member.
  * Create the `example-csharp-public-device` client 
  * Create the `example-go-confidential` client.
  * Create the `example-go-saml` client.
    * Create the `administrator` role.
  * Create the `example-react-public` client.
* Start the example `example-csharp-public-device` client (and test it).
  * Uses the [OAuth 2.0 Device Authorization Grant](https://oauth.net/2/device-flow/) (aka Device Flow).
* Start the example `example-go-confidential` client (and test it).
  * Uses the [OAuth 2.0 Authorization Code Grant](https://oauth.net/2/grant-types/authorization-code/).
  * Uses the [Proof Key for Code Exchange (PKCE)](https://oauth.net/2/pkce/) extension.
* Start the example `example-go-saml` client (and test it).
  * Uses [SAML 2.0](https://en.wikipedia.org/wiki/SAML_2.0).
* Start the example `example-react-public` client (and test it).
  * Uses [OAuth 2.0 Authorization Code Grant](https://oauth.net/2/grant-types/authorization-code/).
  * Uses the [Proof Key for Code Exchange (PKCE)](https://oauth.net/2/pkce/) extension.

# Usage

Install docker compose.

Add the following to your machine `hosts` file:

```
127.0.0.1 keycloak.test
127.0.0.1 mail.test
127.0.0.1 example-go-confidential.test
127.0.0.1 example-go-saml.test
127.0.0.1 example-react-public.test
```

Start the environment:

```bash
./create.sh
```

Try the example applications displayed by the above command. E.g., try the
OpenID Connect Confidential Client as the `alice`:`alice` user at:

http://example-go-confidential.test:8081/auth/login

When anything goes wrong, you can try to troubleshoot at:

* `docker compose logs --follow`
* http://keycloak.test:8080/realms/example/.well-known/openid-configuration (Keycloak OIDC configuration)
* http://keycloak.test:8080/realms/example/protocol/saml/descriptor (Keycloak SAML configuration)
* http://keycloak.test:8080 (Keycloak; login as `admin`:`admin`)
* http://mail.test:8025 (MailHog (email server))
* For SAML troubleshooting, you can use the browser developer tools to capture
  the requests/responses and paste them in the SAML Decoder & Parser at
  https://www.scottbrady91.com/tools/saml-parser.

Destroy everything:

```bash
./destroy.sh
```

# Alternatives

* [Authelia](https://www.authelia.com)
* [Dex](https://dexidp.io)
* [OAuth2 Proxy](https://github.com/oauth2-proxy/oauth2-proxy)
* [Ory Hydra](https://www.ory.sh)
* [Zitadel](https://github.com/zitadel/zitadel)
