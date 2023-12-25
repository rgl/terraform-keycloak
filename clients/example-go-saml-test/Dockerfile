# syntax=docker/dockerfile:1.6
FROM golang:1.21-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM chromedp/headless-shell:116.0.5845.14
COPY --from=builder /app/example-go-saml-test .
WORKDIR /app
ENTRYPOINT ["/example-go-saml-test"]
