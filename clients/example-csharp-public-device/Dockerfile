# syntax=docker/dockerfile:1.6
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS builder
WORKDIR /app
COPY *.csproj ./
RUN dotnet restore
COPY *.cs ./
# see https://learn.microsoft.com/en-us/dotnet/core/rid-catalog#linux-rids
RUN dotnet publish \
        --runtime debian.11-x64 \
        --self-contained \
        --configuration Release \
        --output bin/out

FROM debian:bullseye-slim
RUN <<EOF
#!/bin/bash
set -euxo pipefail
apt-get update
# install the dotnet dependencies.
# see https://github.com/dotnet/core/blob/main/release-notes/6.0/linux-packages.md#debian-11-bullseye
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
COPY --from=builder /app/bin/out/ExampleCsharpPublicDevice .
ENTRYPOINT ["/ExampleCsharpPublicDevice"]
