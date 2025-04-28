package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"zigsmith.com/www/cache"
	"zigsmith.com/www/db"
	"zigsmith.com/www/handlers"
	"zigsmith.com/www/log"
)

const (
	listenDefault   = ":8080"
	shutdownTimeout = 5 * time.Second
	timeout         = time.Minute
)

func main() {
	log.Out.Println("initializing database...")
	if err := db.InitDb(); err != nil {
		log.Err.Fatalf("failed to initialize database: %v", err)
	}

	if err := cache.InitCaches(); err != nil {
		log.Err.Fatalf("failed to update caches: %v", err)
	}

	listen := os.Getenv("ZS_LISTEN")
	if listen == "" {
		listen = listenDefault
	}

	log.Out.Printf("starting server at %s...\n", listen)
	server := &http.Server{
		Addr:              listen,
		Handler:           handler(),
		ReadHeaderTimeout: timeout,
	}
	go startServer(server)

	ctx, stop := signal.NotifyContext(
		context.Background(),
		os.Interrupt,
		syscall.SIGTERM,
	)
	defer stop()

	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(
		context.Background(),
		shutdownTimeout,
	)
	defer cancel()

	log.Out.Println("shutting down server...")
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Err.Printf("failed to shutdown server: %v", err)
	}

	log.Out.Println("closing database...")
	if err := db.Close(); err != nil {
		log.Err.Printf("failed to close database: %v", err)
	}
}

func handler() *http.ServeMux {
	r := http.NewServeMux()
	r.Handle("/", handlers.RootHandler())
	r.Handle("/api/", http.StripPrefix("/api", handlers.ApiHandler()))

	return r
}

func startServer(server *http.Server) {
	if err := server.ListenAndServe(); err != nil &&
		err != http.ErrServerClosed {
		log.Err.Fatalf("server failed: %v", err)
	}
}
