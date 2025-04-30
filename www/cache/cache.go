package cache

import (
	"context"

	"zigsmith.com/www/db"
)

var BuildCountCache *int = new(int)

func InitCaches() error {
	if err := UpdateBuildCountCache(); err != nil {
		return err
	}

	return nil
}

func UpdateBuildCountCache() error {
	ctx := context.Background()

	count, err := db.CountBuilds(ctx)
	if err != nil {
		return err
	}

	*BuildCountCache = count
	return nil
}
