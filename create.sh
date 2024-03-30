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

# start the environment in background.
docker compose --profile test build
docker compose up --build --detach

# wait for the services to exit.
function wait-for-service {
  echo "Waiting for the $1 service to complete..."
  while true; do
    result="$(docker compose ps --status exited --format json $1)"
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
