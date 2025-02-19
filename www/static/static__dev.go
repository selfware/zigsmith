//go:build !release

package static

import "os"

var Public = os.DirFS("./static/public")
