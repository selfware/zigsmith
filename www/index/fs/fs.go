package fs

import (
	"errors"
	"fmt"
	"io"
	"io/fs"
	"mime"
	"net/http"
	"path/filepath"

	"zigsmith.com/www/index"
)

func new(config any, path string) (http.Handler, error) {
	f, _ := config.(fs.FS)

	file, err := f.Open(path)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return nil, nil
		}
		return nil, fmt.Errorf("fs.FS.Open: %w", err)
	}
	defer file.Close()

	stat, err := file.Stat()
	if err != nil {
		return nil, fmt.Errorf("fs.File.Stat: %w", err)
	}
	if stat.IsDir() {
		return nil, nil
	}

	mime := mime.TypeByExtension(filepath.Ext(path))
	if mime == "" {
		mime = "application/octet-stream"
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", mime)
		if _, err := io.Copy(w, file); err != nil {
			http.Error(
				w,
				"failed to send file",
				http.StatusInternalServerError,
			)
		}
	}), nil
}

func init() {
	index.Register("fs", new)
}
