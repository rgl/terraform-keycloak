#!/bin/bash
set -euo pipefail
update-ca-trust
keytool \
    -v \
    -importkeystore \
    -srcstoretype PKCS12 \
    -srckeystore "/etc/pki/$KC_HOSTNAME-key.p12" \
    -srcstorepass '' \
    -srcalias 1 \
    -deststoretype PKCS12 \
    -destkeystore /opt/keycloak/conf/server.keystore \
    -deststorepass 'password' \
    -destalias server
exec su -s /bin/bash keycloak /opt/keycloak/bin/kc.sh "$@"
