-- ==============================================================
-- 1. CONFIGURAÇÕES DE SCHEMAS
-- ==============================================================
-- No RDS, em vez de dropar o public, apenas removemos o acesso
REVOKE ALL ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS gl_user;
CREATE SCHEMA IF NOT EXISTS gl_lista;
CREATE SCHEMA IF NOT EXISTS gl_notification;

-- ==============================================================
-- 2. CRIAÇÃO DOS USUÁRIOS (ADMIN E APP)
-- ==============================================================
-- Usuários Admin (Donos dos Schemas para o Flyway)
CREATE USER gl_user WITH PASSWORD 'gl_user';
CREATE USER gl_lista WITH PASSWORD 'gl_lista';
CREATE USER gl_notification WITH PASSWORD 'gl_notification';

-- Usuários de Runtime (Uso da Aplicação Spring)
CREATE USER gl_user_app WITH PASSWORD 'gl_user';
CREATE USER gl_lista_app WITH PASSWORD 'gl_lista';
CREATE USER gl_notification_app WITH PASSWORD 'gl_notification';

-- ==============================================================
-- 3. PROPRIEDADE (OWNERSHIP)
-- ==============================================================
-- Essencial para o Flyway gerenciar o histórico sem erros
ALTER SCHEMA gl_user OWNER TO gl_user;
ALTER SCHEMA gl_lista OWNER TO gl_lista;
ALTER SCHEMA gl_notification OWNER TO gl_notification;

-- ==============================================================
-- 4. PERMISSÕES DE CONEXÃO E USO
-- ==============================================================
-- Garante que todos podem se conectar ao banco de dados atual
GRANT CONNECT ON DATABASE postgres TO gl_user, gl_user_app; -- No RDS o padrão costuma ser 'postgres'
GRANT CONNECT ON DATABASE postgres TO gl_lista, gl_lista_app;
GRANT CONNECT ON DATABASE postgres TO gl_notification, gl_notification_app;

-- Permite que os usuários _app "entrem" nos seus respectivos schemas
GRANT USAGE ON SCHEMA gl_user TO gl_user_app;
GRANT USAGE ON SCHEMA gl_lista TO gl_lista_app;
GRANT USAGE ON SCHEMA gl_notification TO gl_notification_app;

-- ==============================================================
-- 5. PRIVILÉGIOS DE DADOS (TABELAS E SEQUENCES)
-- ==============================================================

-- A. Privilégios para tabelas JÁ EXISTENTES
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA gl_user TO gl_user_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA gl_user TO gl_user_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA gl_lista TO gl_lista_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA gl_lista TO gl_lista_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA gl_notification TO gl_notification_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA gl_notification TO gl_notification_app;

-- B. PRIVILÉGIOS PADRÃO (Crucial: Define o que acontece com tabelas que o Flyway criará no futuro)
-- Nota: Rodamos isso como o usuário 'postgres' (rds_superuser) para definir a regra
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_user GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_user_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_user GRANT USAGE, SELECT ON SEQUENCES TO gl_user_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA gl_lista GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_lista_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_lista GRANT USAGE, SELECT ON SEQUENCES TO gl_lista_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA gl_notification GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gl_notification_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA gl_notification GRANT USAGE, SELECT ON SEQUENCES TO gl_notification_app;