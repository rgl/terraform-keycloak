# syntax=docker.io/docker/dockerfile:1.7
FROM golang:1.22-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM chromedp/headless-shell:125.0.6368.2
RUN <<EOF
#!/bin/bash
set -euxo pipefail
apt-get update
# install the dotnet dependencies.
# see https://github.com/dotnet/core/blob/main/release-notes/8.0/linux-packages.md
# see https://github.com/dotnet/dotnet-docker/blob/main/src/runtime-deps/8.0/bookworm-slim/amd64/Dockerfile
apt-get install -y --no-install-recommends \
    libc6 \
    libgcc-s1 \
    libicu72 \
    libssl3 \
    libstdc++6 \
    tzdata \
    zlib1g
rm -rf /var/lib/apt/lists/*
EOF
COPY ./tmp/ExampleCsharpPublicDevice .
COPY --from=builder /app/example-csharp-public-device-test .
ENTRYPOINT ["/example-csharp-public-device-test"]
