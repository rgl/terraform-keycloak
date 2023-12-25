# syntax=docker/dockerfile:1.6
FROM golang:1.21-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM debian:12-slim
RUN <<EOF
apt-get update
apt-get install -y ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=builder /app/example-go-saml .
EXPOSE 8082
ENTRYPOINT ["/example-go-saml"]
