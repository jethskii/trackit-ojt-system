-- ============================================================
-- TRACKIT migration: Admin Announcements
--
-- Run this AFTER migration_admin.sql. Non-destructive.
--
-- Lets an admin broadcast an announcement to All Users, Instructors
-- Only, or Students Only. Unlike instructor announcements (which
-- target specific class sections via announcement_targets), an admin
-- announcement targets a whole audience type, so it gets its own
-- simple table rather than reusing announcement_targets.
-- ============================================================

CREATE TABLE IF NOT EXISTS admin_announcements (
  id               BIGSERIAL PRIMARY KEY,
  admin_id         BIGINT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  content          TEXT NOT NULL,
  target_audience  TEXT NOT NULL DEFAULT 'all',
  image_url        TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT admin_announcements_target_check
    CHECK (target_audience IN ('all', 'instructors', 'students'))
);

CREATE INDEX IF NOT EXISTS idx_admin_announcements_created
  ON admin_announcements (created_at DESC);
