# About

[![Build status](https://github.com/rgl/terraform-keycloak/workflows/build/badge.svg)](https://github.com/rgl/terraform-keycloak/actions?query=workflow%3Abuild)

This initializes a Keycloak instance using the [mrparkers/terraform-provider-keycloak](https://github.com/mrparkers/terraform-provider-keycloak) Terraform provider.

This will:

* Create a test Keycloak instance inside a docker container using docker compose.

# Usage

Install docker compose.

Add the following to your machine `hosts` file:

```
127.0.0.1 keycloak.test
```

Start the environment:

```bash
./create.sh
```

When anything goes wrong, you can try to troubleshoot at:

* http://keycloak.test:8080 (Keycloak)
* http://localhost:8025 (MailHog (email server))

Destroy everything:

```bash
./destroy.sh
```

# Alternatives

* [Authelia](https://www.authelia.com)
* [Dex](https://dexidp.io)
* [OAuth2 Proxy](https://github.com/oauth2-proxy/oauth2-proxy)
* [Ory Hydra](https://www.ory.sh)
