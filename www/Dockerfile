FROM docker.io/golang:1-alpine

WORKDIR /root
COPY . .
RUN go mod download
RUN go build -tags release -o /app

EXPOSE 8080
CMD ["/app"]