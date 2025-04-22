package handlers

import (
	"net/http"

	"zigsmith.com/www/fs"
	"zigsmith.com/www/handlers/api"
)

var fileServer = http.FileServerFS(fs.Public)

var RootHandler = http.HandlerFunc(rootHandler)

var ApiHandler = http.StripPrefix("/api", apiHandler())

func rootHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	fileServer.ServeHTTP(w, r)
}

func apiHandler() http.Handler {
	r := http.NewServeMux()
	r.HandleFunc("GET /cdn", api.CdnHandler)
	r.HandleFunc("GET /packages", api.PackagesHandler)
	r.HandleFunc("GET /packages/{name}", api.PackageHandler)
	r.HandleFunc("GET /packages/{name}/{version}", api.VersionHandler)

	return jsonMiddleware(r)
}

func jsonMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rw := &jsonW{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rw, r)

		if rw.status == http.StatusOK && w.Header().Get("Content-Type") == "" {
			w.Header().Set("Content-Type", "application/json")
		}
	})
}

type jsonW struct {
	http.ResponseWriter
	status int
}

func (w *jsonW) WriteHeader(code int) {
	w.status = code
	w.ResponseWriter.WriteHeader(code)
}
