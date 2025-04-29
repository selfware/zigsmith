package api

import (
	"encoding/json"
	"net/http"
	"os"

	"zigsmith.com/www/cache"
	"zigsmith.com/www/db"
	"zigsmith.com/www/log"
)

var apiKey = os.Getenv("ZS_APIKEY")

func BuildsHandler(w http.ResponseWriter, r *http.Request) {
	if !checkKey(r) {
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	var b buildInfo
	if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
		http.Error(w, "invalid body", http.StatusBadRequest)
		return
	}

	if b.Hash == "" || b.Name == "" || b.Version == "" {
		http.Error(w, "missing required fields", http.StatusBadRequest)
		return
	}

	err := db.InsertBuild(r.Context(), b.Hash, b.Name, b.Version)
	if db.HttpError(w, err) {
		return
	}

	cache.UpdatePackageCountCache()

	w.WriteHeader(http.StatusCreated)
}

func PackagesHandler(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	names, err := db.SearchPackages(r.Context(), q)
	if db.HttpError(w, err) {
		return
	}

	var results []packageInfo
	for _, name := range names {
		versions, err := db.GetVersions(r.Context(), name)
		if db.HttpError(w, err) {
			return
		}

		var versionDetails []versionInfo
		for i, version := range versions {
			var vi versionInfo
			vi.Version = version

			if i == 0 {
				vi.Hashes, err = db.GetHashes(r.Context(), name, version)
			} else {
				vi.LatestHash, err = db.GetLatestHash(r.Context(), name, version)
			}

			if db.HttpError(w, err) {
				return
			}

			versionDetails = append(versionDetails, vi)
		}

		results = append(results, packageInfo{
			Name:     name,
			Versions: versionDetails,
		})
	}

	if results == nil {
		results = []packageInfo{}
	}

	writeJson(w, results)
}

func PackageHandler(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")

	versions, err := db.GetVersions(r.Context(), name)
	if db.HttpError(w, err) {
		return
	}

	if versions == nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	writeJson(w, versions)
}

func VersionHandler(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	version := r.PathValue("version")

	hashes, err := db.GetHashes(r.Context(), name, version)
	if db.HttpError(w, err) {
		return
	}

	if hashes == nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	writeJson(w, hashes)
}

type buildInfo struct {
	Hash    string `json:"hash"`
	Name    string `json:"name"`
	Version string `json:"version"`
}

type packageInfo struct {
	Name     string        `json:"name"`
	Versions []versionInfo `json:"versions"`
}

type versionInfo struct {
	Version    string   `json:"version"`
	Hashes     []string `json:"hashes,omitempty"`
	LatestHash string   `json:"latestHash,omitempty"`
}

func writeJson(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(v); err != nil {
		// Headers may have already been written, so just log it.
		log.Err.Printf("response write failed: %v", err)
	}
}

func checkKey(r *http.Request) bool {
	key := r.Header.Get("Authorization")
	return key == "Bearer "+apiKey
}
