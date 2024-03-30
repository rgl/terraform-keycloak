#!/bin/ash
set -euxo pipefail

update-ca-certificates >/dev/null

ash -c 'while ! wget -q --spider https://keycloak.test:8443/realms/master/account/; do sleep 1; done;'

terraform init

terraform plan -out=tfplan

terraform apply tfplan

ash -c 'while ! wget -q --spider https://keycloak.test:8443/realms/example/.well-known/openid-configuration; do sleep 1; done;'
ash -c 'while ! wget -q --spider https://keycloak.test:8443/realms/example/protocol/saml/descriptor; do sleep 1; done;'
