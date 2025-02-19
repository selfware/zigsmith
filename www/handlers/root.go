package handlers

import (
	"net/http"

	"zigsmith.com/www/static"
)

var fs = http.FileServerFS(static.Public)

func RootHandler(w http.ResponseWriter, r *http.Request) {
	fs.ServeHTTP(w, r)
}
