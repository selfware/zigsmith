package handlers

import (
	"html/template"
	"net/http"
	"os"

	"zigsmith.com/www/cache"
	"zigsmith.com/www/embed"
	"zigsmith.com/www/handlers/api"
	"zigsmith.com/www/index"
	_ "zigsmith.com/www/index/fs"
	"zigsmith.com/www/index/tmpl"
)

func RootHandler() http.Handler {
	t, _ := template.ParseFS(embed.Templates, "**.html")

	i := index.New()
	i.Mount("/", "tmpl", &tmpl.Context{
		Tmpl: t,
		Data: templateData{
			CDNUrl:     os.Getenv("ZS_CDNURL"),
			BuildCount: cache.BuildCountCache,
		},
	})
	i.Mount("/static/", "fs", embed.Static)

	return i
}

func ApiHandler() http.Handler {
	r := http.NewServeMux()
	r.HandleFunc("POST /builds", api.BuildsHandler)
	r.HandleFunc("GET /packages", api.PackagesHandler)
	r.HandleFunc("GET /packages/{name}", api.PackageHandler)
	r.HandleFunc("GET /packages/{name}/{version}", api.VersionHandler)

	return r
}

type templateData struct {
	CDNUrl     string
	BuildCount *int
}
