package db

import (
	"database/sql"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"

	"github.com/golang-migrate/migrate/v4"
	pgxm "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	_ "github.com/jackc/pgx/v5/stdlib"

	"zigsmith.com/www/embed"
	"zigsmith.com/www/log"
)

const migration = 0

var db *sql.DB

func InitDb() error {
	src, err := iofs.New(embed.Migrations, ".")
	if err != nil {
		return fmt.Errorf("iofs.New: %w", err)
	}

	db, err = sql.Open("pgx/v5", getPgURI())
	if err != nil {
		return fmt.Errorf("pgx.Connect: %w", err)
	}

	if err := db.Ping(); err != nil {
		return fmt.Errorf("sql.DB.Ping: %w", err)
	}

	driver, err := pgxm.WithInstance(db, &pgxm.Config{})
	if err != nil {
		return fmt.Errorf("pgxm.WithInstance: %w", err)
	}

	m, err := migrate.NewWithInstance("iofs", src, "pgx5", driver)
	if err != nil {
		return fmt.Errorf("migrate.NewWithInstance: %w", err)
	}

	if err := m.Migrate(migration); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("migrate.Migrate.Up: %w", err)
	}

	return nil
}

func Close() error {
	return db.Close()
}

func HttpError(w http.ResponseWriter, err error) bool {
	if err == nil {
		return false
	}

	log.Err.Printf("database failure: %v", err)
	w.WriteHeader(http.StatusInternalServerError)
	return true
}

func getPgURI() string {
	u := url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(os.Getenv("PG_USER"), os.Getenv("PG_PASS")),
		Host:   net.JoinHostPort(os.Getenv("PG_HOST"), os.Getenv("PG_PORT")),
		Path:   os.Getenv("PG_DB"),
	}

	if ssl := os.Getenv("PG_SSLMODE"); ssl != "" {
		q := u.Query()
		q.Add("sslmode", ssl)
		u.RawQuery = q.Encode()
	}

	return u.String()
}
