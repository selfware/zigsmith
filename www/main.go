package main

import (
	"fmt"
	"net/http"
	"os"

	"zigsmith.com/www/handlers"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

const listen = ":8080"

func main() {
	r := chi.NewRouter()
	r.Use(middleware.Compress(9))

	r.Get("/", handlers.RootHandler)

	fmt.Printf("Server listening at %s\n", listen)
	if err := http.ListenAndServe(listen, r); err != nil {
		fmt.Fprintf(os.Stderr, "Server failed: %v\n", err)
		os.Exit(1)
	}
}
