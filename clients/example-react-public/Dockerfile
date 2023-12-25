# syntax=docker/dockerfile:1.6
FROM node:20-bookworm as builder-react
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY src src
COPY public public
RUN npm run build

FROM golang:1.21-bookworm as builder
WORKDIR /app
COPY go.* .
RUN go mod download
COPY *.go .
COPY --from=builder-react /app/build build
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM debian:bookworm-slim
COPY --from=builder /app/example-react-public .
EXPOSE 8083
ENTRYPOINT ["/example-react-public"]
