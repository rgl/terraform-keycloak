# syntax=docker.io/docker/dockerfile:1.9

FROM node:20-bookworm as builder-react
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY src src
COPY public public
RUN npm run build

FROM golang:1.23-bookworm as builder
WORKDIR /app
COPY go.* .
RUN go mod download
COPY *.go .
COPY --from=builder-react /app/build build
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
COPY --from=builder /app/example-react-public /
EXPOSE 8083
ENTRYPOINT ["/entrypoint.sh"]
