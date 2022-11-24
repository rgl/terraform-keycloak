#!/bin/bash
set -euo pipefail

# destroy the existing environment.
#docker compose run --workdir /host destroy
docker compose down --volumes
rm -f terraform.{log,tfstate,tfstate.backup} tfplan
