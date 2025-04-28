package tmpl

import (
	"html/template"
	"net/http"

	"zigsmith.com/www/index"
)

func new(config any, path string) (http.Handler, error) {
	ctx, _ := config.(*Context)

	tmpl := ctx.Tmpl.Lookup(path)
	if tmpl == nil {
		return nil, nil
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := tmpl.Execute(w, ctx.Data); err != nil {
			http.Error(
				w,
				"failed to render page contents",
				http.StatusInternalServerError,
			)
		}
	}), nil
}

func init() {
	index.Register("tmpl", new)
}

type Context struct {
	Tmpl *template.Template
	Data any
}
