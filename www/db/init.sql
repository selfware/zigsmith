-- Only execute this on a database where you don't care about the data. If you
-- use this in production, you're an idiot.

REVOKE CONNECT ON DATABASE current_database() FROM PUBLIC;

SELECT pg_terminate_backend(PID)
FROM PG_STAT_ACTIVITY
WHERE
    DATNAME = current_database()
    AND PID <> pg_backend_pid();

DROP SCHEMA PUBLIC CASCADE;
CREATE SCHEMA PUBLIC CASCADE;

-- And now initialize everything.

GRANT CONNECT ON DATABASE current_database() TO PUBLIC;
