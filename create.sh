#!/bin/bash
set -euo pipefail

# destroy the existing environment.
docker compose down --volumes
rm -f terraform.{log,tfstate,tfstate.backup} tfplan

# start the environment in background.
docker compose up --build --detach

# wait for the services to exit.
function wait-for-service {
  while true; do
    result="$(docker compose ps --status exited --format json $1)"
    if [ -n "$result" ] && [ "$result" != 'null' ]; then
      exit_code="$(jq -r '.[].ExitCode' <<<"$result")"
      break
    fi
    sleep 3
  done
  docker compose logs $1
  return $exit_code
}
wait-for-service init

echo 'Start the login dance at http://localhost:8081 as alice:alice'
