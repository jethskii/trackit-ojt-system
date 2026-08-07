-- ============================================================
-- TRACKIT migration: Instructor auth + teacher dashboard
--
-- Run this AFTER the other migration_*.sql files. Non-destructive.
--
-- Turns advisers (previously just a static contact-info row shown on the
-- student's Profile tab) into real login-capable instructor accounts, so
-- the Teacher module can be genuinely connected to student data instead
-- of mock data. student_profiles.adviser_id already existed but nothing
-- ever set it -- students now pick a real adviser at registration.
-- ============================================================

ALTER TABLE advisers
  ADD COLUMN IF NOT EXISTS password_hash TEXT;

DO $$ BEGIN
  ALTER TABLE advisers ADD CONSTRAINT advisers_email_unique UNIQUE (email);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
