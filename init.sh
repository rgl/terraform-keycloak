#!/bin/ash
set -euxo pipefail

ash -c 'while ! wget -q --spider http://keycloak:8080/realms/master/account/; do sleep 1; done;'

terraform init

terraform plan -out=tfplan

terraform apply tfplan
