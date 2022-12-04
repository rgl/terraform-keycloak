# syntax=docker/dockerfile:1.4
FROM golang:1.19-bullseye as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

FROM chromedp/headless-shell:108.0.5359.48
COPY --from=builder /app/example-react-public-test .
WORKDIR /app
ENTRYPOINT ["/example-react-public-test"]
