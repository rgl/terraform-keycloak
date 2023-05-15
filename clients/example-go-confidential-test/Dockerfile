# syntax=docker/dockerfile:1.4
FROM golang:1.20-bullseye as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM chromedp/headless-shell:113.0.5672.93
COPY --from=builder /app/example-go-confidential-test .
WORKDIR /app
ENTRYPOINT ["/example-go-confidential-test"]
