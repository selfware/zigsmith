BEGIN;

CREATE EXTENSION citext;

CREATE TABLE builds (
    hash       text         PRIMARY KEY,
    name       citext       NOT NULL,
    version    text         NOT NULL,
    timestamp  timestamptz  NOT NULL DEFAULT now()
);

COMMIT;
