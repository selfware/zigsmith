package index

import (
	"net/http"
	"path"
	"strings"

	"zigsmith.com/www/log"
)

func New() *IndexServer {
	return &IndexServer{mux: http.NewServeMux()}
}

type IndexServer struct{ mux *http.ServeMux }

func (srv *IndexServer) Mount(route, driver string, ctx any) {
	d := drivers[driver]
	ctxCopy := ctx

	srv.mux.Handle(
		route,
		http.StripPrefix(
			route,
			http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				h, err := d(ctxCopy, locate(r.URL.Path))
				if err != nil {
					log.Err.Printf(
						"IndexServer driver %s: %v",
						driver,
						err,
					)
					http.Error(
						w,
						"failed to read page contents",
						http.StatusInternalServerError,
					)
					return
				}
				if h != nil {
					h.ServeHTTP(w, r)
					return
				}
				http.NotFound(w, r)
			}),
		),
	)
}

func (server *IndexServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	server.mux.ServeHTTP(w, r)
}

func locate(request string) string {
	clean := path.Clean(request)

	if clean == "." {
		return "index.html"
	}

	if !strings.Contains(clean, ".") {
		return path.Join(clean, "index.html")
	}

	return clean
}
