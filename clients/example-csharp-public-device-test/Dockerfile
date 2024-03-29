# syntax=docker.io/docker/dockerfile:1.7
FROM golang:1.22-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM chromedp/headless-shell:116.0.5845.14
RUN <<EOF
#!/bin/bash
set -euxo pipefail
apt-get update
# install the dotnet dependencies.
# see https://github.com/dotnet/core/blob/main/release-notes/8.0/linux-packages.md#debian-11-bullseye
apt-get install -y --no-install-recommends \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    libicu67 \
    libssl1.1 \
    libstdc++6 \
    zlib1g
rm -rf /var/lib/apt/lists/*
EOF
COPY ./tmp/ExampleCsharpPublicDevice .
COPY --from=builder /app/example-csharp-public-device-test .
ENTRYPOINT ["/example-csharp-public-device-test"]
