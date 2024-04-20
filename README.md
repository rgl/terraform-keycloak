# About

[![Build status](https://github.com/rgl/terraform-keycloak/workflows/build/badge.svg)](https://github.com/rgl/terraform-keycloak/actions?query=workflow%3Abuild)

This initializes a Keycloak instance using the [mrparkers/terraform-provider-keycloak](https://github.com/mrparkers/terraform-provider-keycloak) Terraform provider.

This will:

* Create an example private certification authority.
  * Use it to sign all the used HTTPS certificates.
* Create a test Keycloak instance inside a docker container using docker compose.
* Create the `example` realm.
  * Configure the User Profile.
    * Add the `department` custom attribute.
  * Create the `alice` user.
    * Add the `department` custom attribute.
  * Create the `administrators` group.
    * Assign the `example-go-saml` client `administrator` role.
    * Add the `alice` user as a member.
  * Create the `example-bash-password-client` client.
    * Add the `department` custom claim derived from the `department` user custom attribute.
  * Create the `example-csharp-public-device` client.
  * Create the `example-csharp-client-credentials-server` client.
  * Create the `example-csharp-client-credentials-server-test` client.
    * Add the `project` custom claim.
  * Create the `example-go-client-credentials-server` client.
  * Create the `example-go-client-credentials-server-test` client.
    * Add the `project` custom claim.
  * Create the `example-go-confidential` client.
  * Create the `example-go-saml` client.
    * Create the `administrator` role.
  * Create the `example-react-public` client.
* Start the example `example-csharp-public-device` client (and test it).
  * Uses the [OAuth 2.0 Device Authorization Grant](https://oauth.net/2/device-flow/) (aka Device Flow).
* Start the example `example-csharp-client-credentials-server` server.
  * Authorizes client requests using [OAuth Access Tokens](https://oauth.net/2/access-tokens/) (specifically, [OAuth 2.0 Bearer Tokens](https://oauth.net/2/bearer-tokens/)).
* Start the example `example-go-client-credentials-server` server.
  * Authorizes client requests using [OAuth Access Tokens](https://oauth.net/2/access-tokens/) (specifically, [OAuth 2.0 Bearer Tokens](https://oauth.net/2/bearer-tokens/)).
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
127.0.0.1 example-csharp-client-credentials-server.test
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

Manually try the Go OAuth 2.0 Client Credentials Grant from bash:

```bash
# NB this is the bash equivalent of:
#     clients/example-go-client-credentials-server-test
#     clients/example-go-client-credentials-server
export SSL_CERT_FILE="$PWD/tmp/keycloak-ca/keycloak-ca-crt.pem"
token_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token'
introspection_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token/introspect'
client_id='example-go-client-credentials-server-test'
client_secret='example'
server_client_id='example-go-client-credentials-server'
server_client_secret='example'
token_response="$(curl \
  -s \
  -X POST \
  -u "$client_id:$client_secret" \
  -d "grant_type=client_credentials" \
  -d "client_id=$client_id" \
  -d "client_secret=$client_secret" \
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
# show the (access) token claims.
perl -ne '/.+\.(.+)\.(.+)/ && print $1' <<<"$token" | base64 -d 2>/dev/null | jq
# show the claims returned by the introspection url.
curl \
  -s \
  -X POST \
  -u "$server_client_id:$server_client_secret" \
  -d "token=$token" \
  "$introspection_url" \
  | jq
```

This should return the following claims and values, something alike:

**NB** Notice the presence of the `project` custom claim.

```json
{
  "exp": 1713382890,
  "iat": 1713382590,
  "jti": "fdbae048-85ab-4449-a77e-06d03ac885a1",
  "iss": "https://keycloak.test:8443/realms/example",
  "aud": "account",
  "sub": "3b00d462-9106-420e-97e9-542c4874d36f",
  "typ": "Bearer",
  "azp": "example-go-client-credentials-server-test",
  "acr": "1",
  "realm_access": {
    "roles": [
      "offline_access",
      "default-roles-example",
      "uma_authorization"
    ]
  },
  "resource_access": {
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "email profile",
  "email_verified": false,
  "project": "example",
  "preferred_username": "service-account-example-go-client-credentials-server-test",
  "client_id": "example-go-client-credentials-server-test",
  "username": "service-account-example-go-client-credentials-server-test",
  "token_type": "Bearer",
  "active": true
}
```

Manually try the C# OAuth 2.0 Client Credentials Grant from bash:

```bash
# NB this is the bash equivalent of:
#     clients/example-csharp-client-credentials-server-test
#     clients/example-csharp-client-credentials-server
export SSL_CERT_FILE="$PWD/tmp/keycloak-ca/keycloak-ca-crt.pem"
token_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token'
introspection_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token/introspect'
client_id='example-csharp-client-credentials-server-test'
client_secret='example'
server_url='https://example-csharp-client-credentials-server.test:8027'
server_client_id='example-csharp-client-credentials-server'
server_client_secret='example'
token_response="$(curl \
  -s \
  -X POST \
  -u "$client_id:$client_secret" \
  -d "grant_type=client_credentials" \
  -d "client_id=$client_id" \
  -d "client_secret=$client_secret" \
  "$token_url")"
jq <<<"$token_response"
# NB In Keycloak, this token is a JWT (as defined in the JSON Web Token (JWT)
#    Profile for OAuth 2.0 Access Tokens at
#    https://datatracker.ietf.org/doc/html/rfc9068).
# NB This means we can also use the Keycloak OIDC configuration endpoint at
#    https://keycloak.test:8443/realms/example/.well-known/openid-configuration
#    to drive the token validation based in the JWT issuer URL, like we do in:
#     clients/example-csharp-client-credentials-server
#     clients/example-go-confidential
#     clients/example-react-public
token="$(jq -r .access_token <<<"$token_response")"
# show the (access) token claims.
perl -ne '/.+\.(.+)\.(.+)/ && print $1' <<<"$token" | base64 -d 2>/dev/null | jq
# show the claims returned by the introspection url.
curl \
  -s \
  -X POST \
  -u "$server_client_id:$server_client_secret" \
  -d "token=$token" \
  "$introspection_url" \
  | jq
```

This should return the following claims and values, something alike:

**NB** Notice the presence of the `project` custom claim.

```json
{
  "exp": 1713382969,
  "iat": 1713382669,
  "jti": "4a443912-8e19-471f-b301-1e5c98d904de",
  "iss": "https://keycloak.test:8443/realms/example",
  "aud": "account",
  "sub": "7da88c59-397e-4ec8-959f-0125b1ad73e3",
  "typ": "Bearer",
  "azp": "example-csharp-client-credentials-server-test",
  "acr": "1",
  "realm_access": {
    "roles": [
      "offline_access",
      "default-roles-example",
      "uma_authorization"
    ]
  },
  "resource_access": {
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "email profile",
  "email_verified": false,
  "project": "example",
  "preferred_username": "service-account-example-csharp-client-credentials-server-test",
  "client_id": "example-csharp-client-credentials-server-test",
  "username": "service-account-example-csharp-client-credentials-server-test",
  "token_type": "Bearer",
  "active": true
}
```

Try calling the `example-csharp-client-credentials-server` service using the access token:

```bash
# NB when there is an error, the www-authenticate response header contains
#    the error. for example:
#       www-authenticate: Bearer error="invalid_token", error_description="The token expired at '04/14/2024 10:43:45'"
curl \
  -s \
  -X GET \
  -H "Authorization: Bearer $token" \
  "$server_url/protected" \
  | jq
```

This should return the following claims and values, something alike:

**NB** Notice the presence of the `project` custom claim.

```json
{
  "Claims": [
    {
      "Name": "exp",
      "Value": "1713382969"
    },
    {
      "Name": "iat",
      "Value": "1713382669"
    },
    {
      "Name": "jti",
      "Value": "4a443912-8e19-471f-b301-1e5c98d904de"
    },
    {
      "Name": "iss",
      "Value": "https://keycloak.test:8443/realms/example"
    },
    {
      "Name": "aud",
      "Value": "account"
    },
    {
      "Name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
      "Value": "7da88c59-397e-4ec8-959f-0125b1ad73e3"
    },
    {
      "Name": "typ",
      "Value": "Bearer"
    },
    {
      "Name": "azp",
      "Value": "example-csharp-client-credentials-server-test"
    },
    {
      "Name": "http://schemas.microsoft.com/claims/authnclassreference",
      "Value": "1"
    },
    {
      "Name": "realm_access",
      "Value": "{\"roles\":[\"offline_access\",\"default-roles-example\",\"uma_authorization\"]}"
    },
    {
      "Name": "resource_access",
      "Value": "{\"account\":{\"roles\":[\"manage-account\",\"manage-account-links\",\"view-profile\"]}}"
    },
    {
      "Name": "scope",
      "Value": "email profile"
    },
    {
      "Name": "clientHost",
      "Value": "172.19.0.1"
    },
    {
      "Name": "email_verified",
      "Value": "false"
    },
    {
      "Name": "project",
      "Value": "example"
    },
    {
      "Name": "preferred_username",
      "Value": "service-account-example-csharp-client-credentials-server-test"
    },
    {
      "Name": "clientAddress",
      "Value": "172.19.0.1"
    },
    {
      "Name": "client_id",
      "Value": "example-csharp-client-credentials-server-test"
    }
  ]
}
```

Try OAuth 2.0 Resource Owner Password Credentials Grant (aka Direct Access Grant; aka Password Grant) from bash:

**NB** Although this OAuth 2.0 Grant is supported by Keycloak, its not a [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics#name-resource-owner-password-cre).

```bash
export SSL_CERT_FILE="$PWD/tmp/keycloak-ca/keycloak-ca-crt.pem"
token_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token'
introspection_url='https://keycloak.test:8443/realms/example/protocol/openid-connect/token/introspect'
client_id='example-bash-password-client'
client_secret='example'
user_username='alice'
user_password='alice'
server_url='https://example-csharp-client-credentials-server.test:8027'
server_client_id='example-csharp-client-credentials-server'
server_client_secret='example'
token_response="$(curl \
  -s \
  -X POST \
  -u "$client_id:$client_secret" \
  -d "grant_type=password" \
  -d "client_id=$client_id" \
  -d "client_secret=$client_secret" \
  -d "username=$user_username" \
  -d "password=$user_password" \
  "$token_url")"
jq <<<"$token_response"
# NB In Keycloak, this token is a JWT (as defined in the JSON Web Token (JWT)
#    Profile for OAuth 2.0 Access Tokens at
#    https://datatracker.ietf.org/doc/html/rfc9068).
# NB This means we can also use the Keycloak OIDC configuration endpoint at
#    https://keycloak.test:8443/realms/example/.well-known/openid-configuration
#    to drive the token validation based in the JWT issuer URL, like we do in:
#     clients/example-csharp-client-credentials-server
#     clients/example-go-confidential
#     clients/example-react-public
token="$(jq -r .access_token <<<"$token_response")"
# show the (access) token claims.
perl -ne '/.+\.(.+)\.(.+)/ && print $1' <<<"$token" | base64 -d 2>/dev/null | jq
# show the claims returned by the introspection url.
curl \
  -s \
  -X POST \
  -u "$server_client_id:$server_client_secret" \
  -d "token=$token" \
  "$introspection_url" \
  | jq
```

This should return the following claims and values, something alike:

**NB** Notice the presence of the `department` custom claim.

```json
{
  "exp": 1713632625,
  "iat": 1713632325,
  "jti": "cb9af167-43b9-4884-a0b9-b0ea856e8e03",
  "iss": "https://keycloak.test:8443/realms/example",
  "aud": [
    "example-go-saml",
    "account"
  ],
  "sub": "dc4bde45-1211-45c2-bbfd-fcba56d40e12",
  "typ": "Bearer",
  "azp": "example-bash-password-client",
  "session_state": "fbdd975c-aa21-4fca-9884-8a85964bf101",
  "acr": "1",
  "realm_access": {
    "roles": [
      "offline_access",
      "default-roles-example",
      "uma_authorization"
    ]
  },
  "resource_access": {
    "example-go-saml": {
      "roles": [
        "administrator"
      ]
    },
    "account": {
      "roles": [
        "manage-account",
        "manage-account-links",
        "view-profile"
      ]
    }
  },
  "scope": "profile email",
  "sid": "fbdd975c-aa21-4fca-9884-8a85964bf101",
  "email_verified": true,
  "name": "Alice Doe",
  "preferred_username": "alice",
  "department": "example",
  "given_name": "Alice",
  "family_name": "Doe",
  "email": "alice@example.com",
  "client_id": "example-bash-password-client",
  "username": "alice",
  "token_type": "Bearer",
  "active": true
}
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
