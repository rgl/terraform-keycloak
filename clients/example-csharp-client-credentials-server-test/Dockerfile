# syntax=docker.io/docker/dockerfile:1.12

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
WORKDIR /app
COPY *.csproj ./
RUN dotnet restore
COPY *.cs ./
# see https://learn.microsoft.com/en-us/dotnet/core/rid-catalog#linux-rids
RUN dotnet publish \
        --runtime linux-x64 \
        --self-contained \
        --configuration Release \
        --output bin/out

FROM debian:12-slim
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
    zlib1g \
    ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --chmod=0755 entrypoint.sh /
COPY --from=builder /app/bin/out/ExampleCsharpClientCredentialsServerTest /
EXPOSE 8027
ENTRYPOINT ["/entrypoint.sh"]
