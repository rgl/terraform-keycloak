# syntax=docker.io/docker/dockerfile:1.7
FROM golang:1.22-bookworm as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

# NB we use the bookworm-slim (instead of scratch) image so we can enter the container to execute bash etc.
FROM debian:12-slim
COPY --from=builder /app/example-go-confidential .
EXPOSE 8081
ENTRYPOINT ["/example-go-confidential"]
