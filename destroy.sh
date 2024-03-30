#!/bin/bash
set -euo pipefail

# destroy the existing environment.
#docker compose run --workdir /host destroy
docker compose down --remove-orphans --volumes
for profile in $(yq '.services[].profiles[]' docker-compose.yml | sort --uniq); do
    docker compose --profile $profile down --remove-orphans --volumes
done
rm -f terraform.{log,tfstate,tfstate.backup} tfplan
