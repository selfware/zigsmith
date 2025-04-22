package api

import (
	"encoding/json"
	"net/http"
	"os"

	"zigsmith.com/www/log"
)

var cdnUrl = os.Getenv("ZS_CDNURL")

func CdnHandler(w http.ResponseWriter, r *http.Request) {
	res := map[string]string{"url": cdnUrl}
	writeJson(w, res)
}

func dbError(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}

	log.Err.Printf("database failure: %v", err)
	w.WriteHeader(http.StatusInternalServerError)
	return true
}

func writeJson(w http.ResponseWriter, v any) {
	if err := json.NewEncoder(w).Encode(v); err != nil {
		// Headers may have already been written, so just log it.
		log.Err.Printf("response write failed: %v", err)
	}
}
