package embed

import (
	"embed"
	"io/fs"
)

//go:embed migrations static templates
var content embed.FS

var (
	Migrations, _ = fs.Sub(content, "migrations")
	Static, _     = fs.Sub(content, "static")
	Templates, _  = fs.Sub(content, "templates")
)
