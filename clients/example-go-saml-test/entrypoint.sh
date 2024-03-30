#!/bin/bash
set -euo pipefail

# trust the keycloak ca for OpenSSL based applications (e.g. wget, curl, http).
update-ca-certificates >/dev/null

# trust the keycloak ca for NSS based applications (e.g. chromium, chrome).
# see https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS/Tools.
certutil \
    -d sql:$HOME/.pki/nssdb \
    -A \
    -t 'C,,' \
    -n keycloak \
    -i /usr/local/share/ca-certificates/keycloak.crt

# execute the cmd.
exec "$@"
