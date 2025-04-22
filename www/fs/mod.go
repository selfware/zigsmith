package fs

import (
	"embed"
	"io/fs"
)

var (
	//go:embed migrations
	migrations embed.FS
	//go:embed public
	public embed.FS
)

var Migrations, _ = fs.Sub(migrations, "migrations")
var Public, _ = fs.Sub(public, "public")
