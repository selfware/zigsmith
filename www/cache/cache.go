package cache

import (
	"context"

	"zigsmith.com/www/db"
)

var PackageCountCache *int = new(int)

func InitCaches() error {
	if err := UpdatePackageCountCache(); err != nil {
		return err
	}

	return nil
}

func UpdatePackageCountCache() error {
	ctx := context.Background()

	count, err := db.CountPackages(ctx)
	if err != nil {
		return err
	}

	*PackageCountCache = count
	return nil
}
