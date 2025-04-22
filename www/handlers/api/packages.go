package api

import (
	"net/http"

	"zigsmith.com/www/db"
)

func PackagesHandler(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query().Get("q")
	if q != "" {
		packagesQueryHandler(w, r, q)
		return
	}

	count, err := db.CountPackages(r.Context())
	if dbError(w, err) {
		return
	}

	res := map[string]int{"count": count}
	writeJson(w, res)
}

func PackageHandler(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")

	versions, err := db.GetVersions(r.Context(), name)
	if dbError(w, err) {
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
	if dbError(w, err) {
		return
	}

	if hashes == nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	writeJson(w, hashes)
}

func packagesQueryHandler(w http.ResponseWriter, r *http.Request, q string) {
	names, err := db.SearchPackages(r.Context(), q)
	if dbError(w, err) {
		return
	}

	var results []packageInfo
	for _, name := range names {
		versions, err := db.GetVersions(r.Context(), name)
		if dbError(w, err) {
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

			if dbError(w, err) {
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

type packageInfo struct {
	Name     string        `json:"name"`
	Versions []versionInfo `json:"versions"`
}

type versionInfo struct {
	Version    string   `json:"version"`
	Hashes     []string `json:"hashes,omitempty"`
	LatestHash string   `json:"latestHash,omitempty"`
}
