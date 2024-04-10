#!/bin/bash
set -euo pipefail

# destroy the existing environment.
./destroy.sh

# create the certificates.
docker compose build certificates
docker compose run certificates

# create the example-go-saml rsa key and certificate.
# NB the public part (the certificate) is shared with the Keycloak SAML IdP.
make -C clients/example-go-saml example-go-saml-key.pem

# build example-csharp-public-device and copy it to
# example-csharp-public-device-test/tmp/ExampleCsharpPublicDevice.
docker compose --profile example-csharp-public-device build \
  example-csharp-public-device
docker compose --profile example-csharp-public-device run \
  --volume "$PWD/clients/example-csharp-public-device-test/tmp/:/host" \
  --entrypoint cp \
  example-csharp-public-device \
  /ExampleCsharpPublicDevice /host
docker compose --profile example-csharp-public-device build \
  example-csharp-public-device-test

# build (the images that have profiles).
for profile in $(yq '.services[].profiles[]' docker-compose.yml | sort --uniq); do
    docker compose --profile $profile build
done

# start the environment in background.
docker compose up --build --detach

# wait for the services to exit.
function wait-for-service {
  local service="$1"
  local timeout_s="${2:-300}"
  local start_time_s=$(date +%s)
  echo "Waiting for the $service service to exit..."
  while true; do
    local result="$(docker compose ps --no-trunc --all --status exited --format json "$service")"
    if [ -n "$result" ] && [ "$result" != 'null' ]; then
      local exit_code="$(jq -r '.ExitCode' <<<"$result")"
      break
    fi
    sleep 3
    local elapsed_time_s=$(( $(date +%s) - $start_time_s ))
    if [ $elapsed_time_s -ge $timeout_s ]; then
      echo "ERROR: Timeout reached ($timeout_s seconds)."
      docker version 2>&1 \
        | perl -pe 's/^/DEBUG: docker version: /'
      docker compose version 2>&1 \
        | perl -pe 's/^/DEBUG: docker compose version: /'
      local exit_code=1
      break
    fi
  done
  docker compose logs "$service"
  return $exit_code
}
wait-for-service init

# execute the automatic tests.
cat <<'EOF'

#### Automated tests results

EOF
echo 'example-csharp-public-device client test:'
docker compose --profile example-csharp-public-device run example-csharp-public-device-test | sed -E 's,^(.*),  \1,g'
echo
echo 'example-go-client-credentials-server client test:'
docker compose --profile example-go-client-credentials-server-test run example-go-client-credentials-server-test | sed -E 's,^(.*),  \1,g'
echo
echo 'example-go-confidential client test:'
docker compose --profile test run example-go-confidential-test | sed -E 's,^(.*),  \1,g'
echo
echo 'example-go-saml client test:'
docker compose --profile test run example-go-saml-test | sed -E 's,^(.*),  \1,g'
echo
echo 'example-react-public client test:'
docker compose --profile test run example-react-public-test | sed -E 's,^(.*),  \1,g'

# show how to use the system.
cat <<'EOF'

#### Manual tests

example-csharp-public-device client:
  Execute:
    docker compose --profile example-csharp-public-device run example-csharp-public-device

example-go-client-credentials-server client:
  Execute:
    docker compose --profile example-go-client-credentials-server-test run example-go-client-credentials-server-test

example-go-confidential client:
  Start the login dance at https://example-go-confidential.test:8081 as alice:alice

example-go-saml client:
  Start the login dance at https://example-go-saml.test:8082 as alice:alice

example-react-public client:
  Start the login dance at https://example-react-public.test:8083 as alice:alice

keycloak example realm:
  https://keycloak.test:8443/admin/master/console/#/example/clients
  https://keycloak.test:8443/realms/example/.well-known/openid-configuration
  https://keycloak.test:8443/realms/example/protocol/saml/descriptor
EOF
