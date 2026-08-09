-- ============================================================
-- TRACKIT migration: Admin Profile (avatar, sessions, password OTP)
--
-- Run this AFTER migration_hte_directory.sql. Non-destructive.
-- ============================================================

ALTER TABLE admins
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

-- Mirrors the student login_history table: one row per login, closed on
-- logout. revoked_at additionally lets "Terminate Session" actually mean
-- something -- requireAdminAuth checks this on every request, so a
-- revoked session's token stops working immediately, not just
-- cosmetically in the UI.
CREATE TABLE IF NOT EXISTS admin_login_history (
  id          BIGSERIAL PRIMARY KEY,
  admin_id    BIGINT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  login_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  logout_at   TIMESTAMPTZ,
  revoked_at  TIMESTAMPTZ,
  user_agent  TEXT,
  ip_address  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_login_history_admin
  ON admin_login_history (admin_id, login_at DESC);

-- One-time codes for the change-password email verification flow. Codes
-- are stored bcrypt-hashed (never plaintext), expire, and are single-use
-- (used_at). attempts guards against brute-forcing a 6-digit code.
CREATE TABLE IF NOT EXISTS admin_password_otps (
  id           BIGSERIAL PRIMARY KEY,
  admin_id     BIGINT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  code_hash    TEXT NOT NULL,
  attempts     SMALLINT NOT NULL DEFAULT 0,
  expires_at   TIMESTAMPTZ NOT NULL,
  verified_at  TIMESTAMPTZ,
  used_at      TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_password_otps_admin
  ON admin_password_otps (admin_id, created_at DESC);
