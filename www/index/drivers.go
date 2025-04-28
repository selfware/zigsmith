package index

import "net/http"

var drivers = make(map[string]Driver)

func Register(name string, driver Driver) {
	drivers[name] = driver
}

type Driver func(any, string) (http.Handler, error)
