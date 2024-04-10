#!/bin/bash
set -euo pipefail
update-ca-certificates >/dev/null
exec /example-go-client-credentials-server "$@"
