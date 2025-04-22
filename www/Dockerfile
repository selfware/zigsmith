FROM golang:alpine AS builder

WORKDIR /src
COPY . .
RUN go mod download
RUN go build

FROM alpine:latest

COPY --from=builder /src/www /app

EXPOSE 8080
ENTRYPOINT ["/app"]
