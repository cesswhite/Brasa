create table "auth_user" ("id" text not null primary key, "name" text not null, "email" text not null unique, "emailVerified" integer not null, "image" text, "createdAt" date not null, "updatedAt" date not null);

create table "auth_session" ("id" text not null primary key, "expiresAt" date not null, "token" text not null unique, "createdAt" date not null, "updatedAt" date not null, "ipAddress" text, "userAgent" text, "userId" text not null references "auth_user" ("id") on delete cascade);

create table "auth_provider_account" ("id" text not null primary key, "accountId" text not null, "providerId" text not null, "userId" text not null references "auth_user" ("id") on delete cascade, "accessToken" text, "refreshToken" text, "idToken" text, "accessTokenExpiresAt" date, "refreshTokenExpiresAt" date, "scope" text, "password" text, "createdAt" date not null, "updatedAt" date not null);

create table "auth_verification" ("id" text not null primary key, "identifier" text not null, "value" text not null, "expiresAt" date not null, "createdAt" date not null, "updatedAt" date not null);

create table "auth_device_code" ("id" text not null primary key, "deviceCode" text not null, "userCode" text not null, "userId" text, "expiresAt" date not null, "status" text not null, "lastPolledAt" date, "pollingInterval" integer, "clientId" text, "scope" text);

create table "auth_passkey" ("id" text not null primary key, "name" text, "publicKey" text not null, "userId" text not null references "auth_user" ("id") on delete cascade, "credentialID" text not null, "counter" integer not null, "deviceType" text not null, "backedUp" integer not null, "transports" text, "createdAt" date, "aaguid" text);

create index "auth_session_userId_idx" on "auth_session" ("userId");

create index "auth_provider_account_userId_idx" on "auth_provider_account" ("userId");

create index "auth_verification_identifier_idx" on "auth_verification" ("identifier");

create index "auth_passkey_userId_idx" on "auth_passkey" ("userId");

create index "auth_passkey_credentialID_idx" on "auth_passkey" ("credentialID");

create unique index "auth_device_code_deviceCode_uidx" on "auth_device_code" ("deviceCode");

create unique index "auth_device_code_userCode_uidx" on "auth_device_code" ("userCode");

-- Brasa application boundary. Auth tables above were generated with Better Auth 1.7.5.
CREATE UNIQUE INDEX auth_passkey_unique_credential ON auth_passkey(credentialID);
CREATE TABLE auth_account_links (auth_user_id TEXT PRIMARY KEY REFERENCES auth_user(id), account_id TEXT NOT NULL UNIQUE REFERENCES accounts(id), created_at TEXT NOT NULL);
CREATE TABLE auth_registration (context_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL UNIQUE, name TEXT NOT NULL, expires_at INTEGER NOT NULL, consumed_at INTEGER, claim_id TEXT);
CREATE INDEX auth_registration_expiry ON auth_registration(expires_at);
CREATE TABLE auth_throttle (bucket TEXT PRIMARY KEY, hits INTEGER NOT NULL, expires_at INTEGER NOT NULL);
CREATE INDEX auth_throttle_expiry ON auth_throttle(expires_at);
CREATE INDEX auth_device_code_expiry ON auth_device_code(expiresAt);
CREATE INDEX auth_verification_expiry ON auth_verification(expiresAt);
