-- ==============================================================
-- 1. SEGURANÇA BÁSICA
-- ==============================================================
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- ==============================================================
-- 2. CRIAÇÃO DOS SCHEMAS
-- ==============================================================
CREATE SCHEMA IF NOT EXISTS gl_user;
CREATE SCHEMA IF NOT EXISTS gl_lista;
CREATE SCHEMA IF NOT EXISTS gl_notification;

-- ==============================================================
-- 3. CRIAÇÃO DOS USUÁRIOS
-- ==============================================================

DO $$
BEGIN
  -- Owners / Flyway
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_user') THEN
    CREATE USER gl_user WITH PASSWORD 'gl_user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_lista') THEN
    CREATE USER gl_lista WITH PASSWORD 'gl_lista';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_notification') THEN
    CREATE USER gl_notification WITH PASSWORD 'gl_notification';
  END IF;

  -- Runtime apps
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_user_app') THEN
    CREATE USER gl_user_app WITH PASSWORD 'gl_user';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_lista_app') THEN
    CREATE USER gl_lista_app WITH PASSWORD 'gl_lista';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'gl_notification_app') THEN
    CREATE USER gl_notification_app WITH PASSWORD 'gl_notification';
  END IF;
END$$;

-- ==============================================================
-- 4. OWNERSHIP DOS SCHEMAS
-- ==============================================================
ALTER SCHEMA gl_user OWNER TO gl_user;
ALTER SCHEMA gl_lista OWNER TO gl_lista;
ALTER SCHEMA gl_notification OWNER TO gl_notification;

-- ==============================================================
-- 5. CONEXÃO AO DATABASE
-- ==============================================================
GRANT CONNECT ON DATABASE glaiss TO
  gl_user, gl_user_app,
  gl_lista, gl_lista_app,
  gl_notification, gl_notification_app;

-- Permitir uso do schema
GRANT USAGE ON SCHEMA gl_user TO gl_user_app;

-- Tabelas existentes
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA gl_user
TO gl_user_app;

-- Sequences existentes
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA gl_user
TO gl_user_app;

-- DEFAULT PRIVILEGES (FUTURAS TABELAS)
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_user
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_user_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA gl_user
GRANT USAGE, SELECT ON SEQUENCES TO gl_user_app;

-- Permitir uso do schema
GRANT USAGE ON SCHEMA gl_lista TO gl_lista_app;

-- Tabelas existentes
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA gl_lista
TO gl_lista_app;

-- Sequences existentes
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA gl_lista
TO gl_lista_app;

-- DEFAULT PRIVILEGES (FUTURAS TABELAS)
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_lista
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_lista_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA gl_lista
GRANT USAGE, SELECT ON SEQUENCES TO gl_lista_app;

-- Permitir uso do schema
GRANT USAGE ON SCHEMA gl_notification TO gl_notification_app;

-- Tabelas existentes
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA gl_notification
TO gl_notification_app;

-- Sequences existentes
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA gl_notification
TO gl_notification_app;

-- DEFAULT PRIVILEGES (FUTURAS TABELAS)
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_notification
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_notification_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA gl_notification
GRANT USAGE, SELECT ON SEQUENCES TO gl_notification_app;