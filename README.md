# About

[![Build status](https://github.com/rgl/terraform-keycloak/workflows/build/badge.svg)](https://github.com/rgl/terraform-keycloak/actions?query=workflow%3Abuild)

This initializes a Keycloak instance using the [mrparkers/terraform-provider-keycloak](https://github.com/mrparkers/terraform-provider-keycloak) Terraform provider.

This will:

* Create an example private certification authority.
  * Use it to sign all the used HTTPS certificates.
* Create a test Keycloak instance inside a docker container using docker compose.
* Create the `example` realm.
  * Create the `alice` user.
  * Create the `administrators` group.
    * Assign the `example-go-saml` client `administrator` role.
    * Add the `alice` user as a member.
  * Create the `example-csharp-public-device` client 
  * Create the `example-go-client-credentials-server` client 
  * Create the `example-go-client-credentials-server-test` client 
  * Create the `example-go-confidential` client.
  * Create the `example-go-saml` client.
    * Create the `administrator` role.
  * Create the `example-react-public` client.
* Start the example `example-csharp-public-device` client (and test it).
  * Uses the [OAuth 2.0 Device Authorization Grant](https://oauth.net/2/device-flow/) (aka Device Flow).
* Start the example `example-go-client-credentials-server` server.
  * Authorizes client requests using [OAuth Access Tokens](https://oauth.net/2/access-tokens/) (specifically, [OAuth 2.0 Bearer Tokens](https://oauth.net/2/bearer-tokens/)).
  * Only accepts requests from the `example-go-client-credentials-server-test` client.
* Start the example `example-go-client-credentials-server-test` client.
  * Uses the [OAuth 2.0 Client Credentials Grant](https://oauth.net/2/grant-types/client-credentials/).
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
127.0.0.1 example-go-client-credentials-server.test
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

https://example-go-confidential.test:8081/auth/login

When anything goes wrong, you can try to troubleshoot at:

* `docker compose logs --follow`
* https://keycloak.test:8443/realms/example/.well-known/openid-configuration (Keycloak OIDC configuration)
* https://keycloak.test:8443/realms/example/protocol/saml/descriptor (Keycloak SAML configuration)
* https://keycloak.test:8443 (Keycloak; login as `admin`:`admin`)
* https://mail.test:8025 (Mailpit (email server))
* For SAML troubleshooting, you can use the browser developer tools to capture
  the requests/responses and paste them in the SAML Decoder & Parser at
  https://www.scottbrady91.com/tools/saml-parser.

Manually try the OAuth 2.0 Client Credentials Grant from bash:

```bash
# NB this is the bash equivalent of:
#     clients/example-go-client-credentials-server-test
#     clients/example-go-client-credentials-server
token_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token'
introspection_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token/introspect'
client_id='example-go-client-credentials-server-test'
client_secret='example'
server_client_id='example-go-client-credentials-server'
server_client_secret='example'
token_response="$(curl \
  -k \
  -s \
  -X POST \
  -u "$client_id:$client_secret" \
  -d "grant_type=client_credentials&client_id=$client_id&client_secret=$client_secret" \
  "$token_url")"
jq <<<"$token_response"
# NB In Keycloak, this token is a JWT (as defined in the JSON Web Token (JWT)
#    Profile for OAuth 2.0 Access Tokens at
#    https://datatracker.ietf.org/doc/html/rfc9068).
# NB This means we can also use the Keycloak OIDC configuration endpoint at
#    https://keycloak.test:8443/realms/example/.well-known/openid-configuration
#    to drive the token validation based in the JWT issuer URL, like we do in:
#     clients/example-go-confidential
#     clients/example-react-public
token="$(jq -r .access_token <<<"$token_response")"
curl \
  -k \
  -s \
  -X POST \
  -u "$server_client_id:$server_client_secret" \
  -d "token=$token" \
  "$introspection_url" \
  | jq
```

Destroy everything:

```bash
./destroy.sh
```

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

# Alternatives

* [Authelia](https://www.authelia.com)
* [Dex](https://dexidp.io)
* [OAuth2 Proxy](https://github.com/oauth2-proxy/oauth2-proxy)
* [Ory Hydra](https://www.ory.sh)
* [Zitadel](https://github.com/zitadel/zitadel)
