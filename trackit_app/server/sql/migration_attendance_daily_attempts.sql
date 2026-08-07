-- ============================================================
-- TRACKIT migration: Daily Clock In/Out attempt limit
--
-- Run this AFTER migration_announcement_images.sql. Non-destructive.
--
-- Students get 2 clock-in attempts per calendar day (tracked per
-- attendance_records row, which is already one row per student per
-- work_date -- no new table needed). Only a successful CLOCK IN
-- consumes an attempt; clocking out just closes whatever cycle is
-- currently open and is always allowed regardless of attempts left,
-- so a normal full day (one clock in + one clock out) only spends 1
-- of the 2 attempts, leaving a spare for a genuine mistake. See
-- routes/attendance.js for the atomic increment logic that makes this
-- limit unbypassable from the client (server/DB is the source of
-- truth, not frontend state).
-- ============================================================

ALTER TABLE attendance_records
  ADD COLUMN IF NOT EXISTS attempts_used SMALLINT NOT NULL DEFAULT 0;

DO $$ BEGIN
  ALTER TABLE attendance_records
    ADD CONSTRAINT chk_attendance_attempts_used CHECK (attempts_used >= 0 AND attempts_used <= 2);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
