package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
)

func CountPackages(ctx context.Context) (int, error) {
	var count int
	err := queryOne(ctx, `
		SELECT COUNT(DISTINCT name)
		FROM builds
	`, []any{&count})

	return count, err
}

func SearchPackages(ctx context.Context, query string) ([]string, error) {
	return queryStrings(ctx, `
		SELECT DISTINCT name
		FROM builds
		WHERE name ILIKE $1
	`, "%"+query+"%")
}

func GetVersions(ctx context.Context, name string) ([]string, error) {
	return queryStrings(ctx, `
		SELECT version
		FROM builds
		WHERE name = $1
		GROUP BY version
		ORDER BY MAX(timestamp) DESC
	`, name)
}

func GetLatestHash(ctx context.Context, name, version string) (string, error) {
	var hash string
	err := queryOne(ctx, `
		SELECT hash
		FROM builds
		WHERE name = $1 AND version = $2
		ORDER BY timestamp DESC
		LIMIT 1
	`, []any{&hash}, name, version)

	return hash, err
}

func GetHashes(ctx context.Context, name, version string) ([]string, error) {
	return queryStrings(ctx, `
		SELECT hash
		FROM builds
		WHERE name = $1 AND version = $2
		GROUP BY hash
		ORDER BY MAX(timestamp) DESC
	`, name, version)
}

func queryOne(
	ctx context.Context,
	query string,
	dest []any,
	args ...any,
) error {
	row := db.QueryRowContext(ctx, query, args...)
	if err := row.Scan(dest...); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return ErrNotFound
		}
		return fmt.Errorf("sql.Row.Scan: %w", err)
	}
	return nil
}

func queryStrings(
	ctx context.Context,
	query string,
	args ...any,
) ([]string, error) {
	rows, err := db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("sql.DB.QueryContext: %w", err)
	}
	defer rows.Close()

	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, fmt.Errorf("sql.Rows.Scan: %w", ErrResultFailed)
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("sql.Rows.Next: %w", err)
	}

	return out, nil
}

var (
	ErrExecFailed   = errors.New("exec failed")
	ErrResultFailed = errors.New("result scan failed")
	ErrNotFound     = errors.New("requested item not found")
)
