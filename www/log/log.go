package log

import (
	"log"
	"os"
)

var (
	Out = log.New(os.Stdout, "", log.LstdFlags)
	Err = log.New(os.Stderr, "", log.LstdFlags)
)
