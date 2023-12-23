#!/bin/bash
set -euo pipefail

# destroy the existing environment.
docker compose down --remove-orphans --volumes
rm -f terraform.{log,tfstate,tfstate.backup} tfplan

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

# start the environment in background.
docker compose --profile test build
docker compose up --build --detach

# wait for the services to exit.
function wait-for-service {
  echo "Waiting for the $1 service to complete..."
  while true; do
    result="$(docker compose ps --all --status exited --format json $1)"
    if [ -n "$result" ] && [ "$result" != 'null' ]; then
      exit_code="$(jq -r '.ExitCode' <<<"$result")"
      break
    fi
    sleep 3
  done
  docker compose logs $1
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

example-go-confidential client:
  Start the login dance at http://example-go-confidential.test:8081 as alice:alice

example-go-saml client:
  Start the login dance at http://example-go-saml.test:8082 as alice:alice

example-react-public client:
  Start the login dance at http://example-react-public.test:8083 as alice:alice

keycloak example realm:
  http://keycloak.test:8080/admin/master/console/#/example/clients
  http://keycloak.test:8080/realms/example/.well-known/openid-configuration
  http://keycloak.test:8080/realms/example/protocol/saml/descriptor
EOF
