-- ASP.NET Identity tables (snake_case, Guid PKs) + refresh_tokens

CREATE TABLE IF NOT EXISTS asp_net_roles (
    id                  uuid                NOT NULL PRIMARY KEY,
    name                character varying(256),
    normalized_name     character varying(256),
    concurrency_stamp   text
);

CREATE TABLE IF NOT EXISTS asp_net_users (
    id                      uuid                NOT NULL PRIMARY KEY,
    user_name               character varying(256),
    normalized_user_name    character varying(256),
    email                   character varying(256),
    normalized_email        character varying(256),
    email_confirmed         boolean             NOT NULL DEFAULT false,
    password_hash           text,
    security_stamp          text,
    concurrency_stamp       text,
    phone_number            text,
    phone_number_confirmed  boolean             NOT NULL DEFAULT false,
    two_factor_enabled      boolean             NOT NULL DEFAULT false,
    lockout_end             timestamptz,
    lockout_enabled         boolean             NOT NULL DEFAULT true,
    access_failed_count     integer             NOT NULL DEFAULT 0,
    preferred_language      text                NOT NULL DEFAULT 'en',
    created_at              timestamptz         NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS asp_net_user_claims (
    id          serial      NOT NULL PRIMARY KEY,
    user_id     uuid        NOT NULL REFERENCES asp_net_users(id) ON DELETE CASCADE,
    claim_type  text,
    claim_value text
);

CREATE TABLE IF NOT EXISTS asp_net_user_logins (
    login_provider          text    NOT NULL,
    provider_key            text    NOT NULL,
    provider_display_name   text,
    user_id                 uuid    NOT NULL REFERENCES asp_net_users(id) ON DELETE CASCADE,
    PRIMARY KEY (login_provider, provider_key)
);

CREATE TABLE IF NOT EXISTS asp_net_user_tokens (
    user_id         uuid    NOT NULL REFERENCES asp_net_users(id) ON DELETE CASCADE,
    login_provider  text    NOT NULL,
    name            text    NOT NULL,
    value           text,
    PRIMARY KEY (user_id, login_provider, name)
);

CREATE TABLE IF NOT EXISTS asp_net_user_roles (
    user_id uuid NOT NULL REFERENCES asp_net_users(id) ON DELETE CASCADE,
    role_id uuid NOT NULL REFERENCES asp_net_roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS asp_net_role_claims (
    id          serial  NOT NULL PRIMARY KEY,
    role_id     uuid    NOT NULL REFERENCES asp_net_roles(id) ON DELETE CASCADE,
    claim_type  text,
    claim_value text
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id          uuid        NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES asp_net_users(id) ON DELETE CASCADE,
    token       text        NOT NULL,
    expires_at  timestamptz NOT NULL,
    is_revoked  boolean     NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_asp_net_users_normalized_user_name   ON asp_net_users(normalized_user_name);
CREATE INDEX        IF NOT EXISTS idx_asp_net_users_normalized_email        ON asp_net_users(normalized_email);
CREATE INDEX        IF NOT EXISTS idx_asp_net_user_claims_user_id           ON asp_net_user_claims(user_id);
CREATE INDEX        IF NOT EXISTS idx_asp_net_user_logins_user_id           ON asp_net_user_logins(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_asp_net_roles_normalized_name        ON asp_net_roles(normalized_name);
CREATE INDEX        IF NOT EXISTS idx_asp_net_role_claims_role_id           ON asp_net_role_claims(role_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_tokens_token                  ON refresh_tokens(token);
CREATE INDEX        IF NOT EXISTS idx_refresh_tokens_user_id                ON refresh_tokens(user_id);
