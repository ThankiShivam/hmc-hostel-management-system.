\set ON_ERROR_STOP on
BEGIN;
\ir schema.sql
\ir seed.sql
COMMIT;
