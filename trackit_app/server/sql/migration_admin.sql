-- ============================================================
-- TRACKIT migration: Admin module
--
-- Run this AFTER migration_student_profile_enhancements.sql.
-- Non-destructive.
--
-- There's no admin self-registration screen -- unlike instructor
-- accounts (which anyone can currently create, a known gap), a real
-- department admin account shouldn't be publicly signup-able. This
-- seeds exactly one admin account directly.
--
-- IMPORTANT: change this password immediately after your first login
-- (Admin > Profile > Change Password, once that exists) or by
-- updating password_hash directly via SQL.
--
-- Seeded login:
--   email:    admin@trackit.local
--   password: TrackIt@Admin2026
-- ============================================================

CREATE TABLE IF NOT EXISTS admins (
  id             BIGSERIAL PRIMARY KEY,
  name           TEXT NOT NULL,
  email          TEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO admins (name, email, password_hash)
SELECT 'DCSE Admin', 'admin@trackit.local',
  '$2b$10$WhLrQB8xlkQ2VMPVCPcp7O4tuft2zz.o8jeg4RxjGsvMVNZ4/rEQq'
WHERE NOT EXISTS (SELECT 1 FROM admins WHERE email = 'admin@trackit.local');
