# syntax=docker/dockerfile:1.4
FROM golang:1.20-bullseye as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

# NB we use the bullseye-slim (instead of scratch) image so we can enter the container to execute bash etc.
FROM debian:bullseye-slim
COPY --from=builder /app/example-go-confidential .
EXPOSE 8081
ENTRYPOINT ["/example-go-confidential"]
