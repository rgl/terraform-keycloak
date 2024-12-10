# syntax=docker.io/docker/dockerfile:1.12

FROM golang:1.23-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM debian:12-slim
RUN <<EOF
#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --chmod=0755 entrypoint.sh /
COPY --from=builder /app/example-go-saml /
EXPOSE 8082
ENTRYPOINT ["/entrypoint.sh"]
