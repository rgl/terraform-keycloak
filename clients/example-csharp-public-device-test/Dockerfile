# syntax=docker.io/docker/dockerfile:1.7

FROM mcr.microsoft.com/playwright:v1.43.1
RUN <<'EOF'
#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  libnss3-tools
install -d -m 700 $HOME/.pki/nssdb
certutil -d sql:$HOME/.pki/nssdb -N --empty-password
rm -rf /var/lib/apt/lists/*
EOF
COPY --chmod=0755 entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY ./tmp/ExampleCsharpPublicDevice ./
COPY . ./
CMD ["npm", "run", "test"]
